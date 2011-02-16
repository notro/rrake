require 'rrake/invocation_exception_mixin'
require 'rrake/logging'
require 'rrake/client'

module Rake
  
  # #########################################################################
  # A Task is the basic unit of work in a Rakefile.  Tasks have associated
  # actions (possibly more than one) and a list of prerequisites.  When
  # invoked, a task will first ensure that all of its prerequisites have an
  # opportunity to run and then it will execute its own actions.
  #
  # Tasks are not usually created directly using the new method, but rather
  # use the +file+ and +task+ convenience methods.
  #
  class Task
    include Logging
    include RestClient
    
    UNSAFE_ESCAPING_DOT = Regexp.new("[^#{::URI::PATTERN::UNRESERVED.gsub(".", "")}#{::URI::PATTERN::RESERVED}]", false, 'N') # :nodoc:
    
    DEFAULT_ENV_VAR_EXCLUDE_FILTER = 
      /^(GEM.*|TERM|SHELL|XDG.*|IRB.*|SSH.*|SUDO.*|OLDPWD|RUBY.*|ruby.*|USER|LS_COLORS|_.*|rvm.*|MAIL|PATH|PWD|LANG|SHLVL|HOME|LOGNAME|LESS.*|LINES|COLUMNS|RACK.*)/
    
    # List of prerequisites for a task.
    attr_reader :prerequisites

    # List of actions attached to a task.
    attr_reader :actions

    # Application owning this task.
    attr_accessor :application

    # Comment for this task.  Restricted to a single line of no more than 50
    # characters.
    attr_reader :comment

    # Full text of the (possibly multi-line) comment.
    attr_reader :full_comment

    # Array of nested namespaces names used for task lookup by this task.
    attr_reader :scope

    # File/Line locations of each of the task definitions for this
    # task (only valid if the task was defined with the detect
    # location option set).
    attr_reader :locations

    # List of conditions attached to a task.
    attr_reader :conditions

    attr_accessor :override_needed_block # :nodoc:

    # Remote host on which to execute this task
    attr_reader :remote

    # Url to the remote task
    attr_reader :url

    # Used to filter out environment variables sent to a remote task on execution.
    attr_accessor :env_var_exclude_filter
    
    # Return task name
    def to_s
      name
    end

    def inspect
      "<#{self.class} #{name} => [#{prerequisites.join(', ')}]>"
    end

    # List of sources for task.
    attr_writer :sources
    def sources
      @sources ||= []
    end
    
    # List of prerequisite tasks
    def prerequisite_tasks
      prerequisites.collect { |pre| lookup_prerequisite(pre) }
    end
    
    def lookup_prerequisite(prerequisite_name)
      application[prerequisite_name, @scope]
    end
    private :lookup_prerequisite

    # First source from a rule (nil if no sources)
    def source
      @sources.first if defined?(@sources)
    end
    
    # Create a task named +task_name+ with no actions or prerequisites. Use
    # +enhance+ to add actions and prerequisites.
    def initialize(task_name, app)
      @name = task_name.to_s
      @prerequisites = []
      @actions = []
      @already_invoked = false
      @full_comment = nil
      @comment = nil
      @lock = Monitor.new
      @application = app
      @scope = app.current_scope
      @arg_names = nil
      @locations = []
      @override_needed_block = nil
      @conditions = {}
      @remote = nil
      @url = nil
      @remote_task_created = false
      @env_var_exclude_filter = DEFAULT_ENV_VAR_EXCLUDE_FILTER
      self.log_context = @application.respond_to?(:name) ? @application.name : ''
      debug2 "Created task: #{@name}"
      self.remote = @application.options.remoteurl if @application.respond_to?(:options)
      self.remote ||= ENV['RAKE_REMOTE']
    end

    # Application log object
    def log
      @application.respond_to?(:log) ? @application.log : nil
    end

    # Enhance a task with prerequisites or actions.  Returns self.
    def enhance(deps=nil, &block)
      @prerequisites |= deps if deps
      @actions << block if block_given?
      if @remote and block_given?
        create_remote_task
        rpost("enhance", {:block=>block.to_json})
        debug2 "Added action to remote task '#{@url}' :: #{block.to_json.inspect}"
      end
      self
    end

    # Name of the task, including any namespace qualifiers.
    def name
      @name.to_s
    end

    # Name of task with argument list description.
    def name_with_args # :nodoc:
      if arg_description
        "#{name}#{arg_description}"
      else
        name
      end
    end

    # Argument description (nil if none).
    def arg_description # :nodoc:
      @arg_names ? "[#{(arg_names || []).join(',')}]" : nil
    end

    # Name of arguments for this task.
    def arg_names
      @arg_names || []
    end

    # Reenable the task, allowing its tasks to be executed if the task
    # is invoked again.
    def reenable
      @already_invoked = false
    end

    # Clear the existing prerequisites and actions of a rake task.
    def clear
      clear_prerequisites
      clear_actions
      clear_conditions
      self
    end

    # Clear the existing prerequisites of a rake task.
    def clear_prerequisites
      prerequisites.clear
      self
    end

    # Clear the existing actions on a rake task.
    def clear_actions
      actions.clear
      self
    end

    # Remove the task conditions
    def clear_conditions
      @conditions = {}
    end

    # Invoke the task if it is needed.  Prerequites are invoked first.
    def invoke(*args)
      task_args = TaskArguments.new(arg_names, args)
      invoke_with_call_chain(task_args, InvocationChain::EMPTY)
    end

    # Same as invoke, but explicitly pass a call chain to detect
    # circular dependencies.
    def invoke_with_call_chain(task_args, invocation_chain) # :nodoc:
      new_chain = InvocationChain.append(self, invocation_chain)
      self.log_context = new_chain.to_s[7..-1]
      @lock.synchronize do
        debug "invoke #{name} #{format_trace_flags}"
        if application.options.trace
          puts "** Invoke #{name} #{format_trace_flags}"
        end
        return if @already_invoked
        @already_invoked = true
        invoke_prerequisites(task_args, new_chain)
        execute(task_args) if needed?
      end
    rescue Exception => ex
      add_chain_to(ex, new_chain)
      raise ex
    end
    protected :invoke_with_call_chain

    def add_chain_to(exception, new_chain)
      exception.extend(InvocationExceptionMixin) unless exception.respond_to?(:chain)
      exception.chain = new_chain if exception.chain.nil?
    end
    private :add_chain_to

    # Invoke all the prerequisites of a task.
    def invoke_prerequisites(task_args, invocation_chain) # :nodoc:
      prerequisite_tasks.each { |prereq|
        prereq_args = task_args.new_scope(prereq.arg_names)
        prereq.invoke_with_call_chain(prereq_args, invocation_chain)
      }
    end

    # Format the trace flags for display.
    def format_trace_flags
      flags = []
      flags << "first_time" unless @already_invoked
      flags << "not_needed" unless needed?
      flags.empty? ? "" : "(" + flags.join(", ") + ")"
    end
    private :format_trace_flags

    # Execute the actions associated with this task. 
    # (task arguments is not supported for remote tasks)
    def execute(args=nil) # TODO: implement argument handling for remote tasks
      args ||= EMPTY_TASK_ARGS
      debug "Execute #{remote ? '' : 'local '}#{application.options.dryrun ? '(dry run) ' : ''}#{name}#{remote ? '(' + url + ')' : ''}"
      if application.options.dryrun
        puts "** Execute (dry run) #{name}"
        return
      end
      if application.options.trace
        puts "** Execute #{name}"
      end
      if remote
        raise "task arguments is not supported for remote tasks" unless args.nil? or args.to_hash.empty?
        create_remote_task
        env = ENV.to_hash.reject { |k,v| k =~ env_var_exclude_filter }
        hash = rput("execute", {"env_var" => env})
        exception = hash["exception"]
        if exception[0]
          fatal "Error executing remote task #{url}. #{exception[1]} => #{exception[2]}"
          debug "Stack trace: #{exception[3]}"
          raise eval(exception[1]), exception[2]
        end
        exit_status = hash["exit_status"]
        exit exit_status[1] if exit_status[0]
        hash["output"].each { |std, s|
          case std
            when "stdout"
              print s unless application.options.silent
              type = ""
            when "stderr"
              $stderr.print s unless application.options.silent
              type = "stderr: "
            else
              raise "unknown outputtype: #{std} returned from execute '#{url}'"
          end
          s.split.each {|str| info "#{type}#{str}" }
        }
        return
      end
      application.enhance_with_matching_rule(name) if @actions.empty?
      @actions.each do |act|
        case act.arity
        when 1
          act.call(self)
        else
          act.call(self, args)
        end
      end
    end

    # When needed? is called to find out if
    # the task should execute it's action,
    # the supplied block will be called.
    # Brackets {} is not supported. Must use do/end.
    #
    #   #This task will not run
    #   task :task1 do
    #     puts "never gets here"
    #   end
    #   Rake::Task[:task1].override_needed do |t|
    #     false
    #   end
    def override_needed(&block)
      @override_needed_block = block
      if remote
        create_remote_task
        rpost("override_needed", {:block => block.to_json})
        debug2 "override_needed on remote task '#{@url}' :: #{block.to_json.inspect}"
      end
    end

    # Is this task needed?
    #
    # Return true if not override_needed has been used or the task has been conditioned.
    def needed?
      if remote
        create_remote_task
        rget "needed"
      elsif @override_needed_block != nil
        @override_needed_block.call(self)
      elsif @conditions != {} then
        condition_keys = @conditions.keys.map {|key| key.to_s}
        if (condition_keys & prerequisites) != condition_keys then
          fail "not all conditions found in prerequisites"
        end
        result = true
        @conditions.each do |key, value|
          task = application.lookup(key.to_s, [scope])
          if task then
            result &= (task.needed? == value)
          else
            fail "Task: #{key} not found"
          end
        end
        result
      else
        true
      end
    end

    # Timestamp for this task.  Basic tasks return the current time for their
    # time stamp.  Other tasks can be more sophisticated.
    def timestamp
      t = prerequisite_tasks.collect { |pre| pre.timestamp }.max
      return t if t
      if remote
        create_remote_task
        Time.at rget("timestamp")
      else
        Time.now
      end
    end

    # Add conditions to the task.
    # Will overwrite any existing conditions for a prerequisite.
    #
    # override_needed will override these conditions.
    def add_conditions(conditions)
      @conditions.merge!(conditions)
    end
   
    # Add a description to the task.  The description can consist of an option
    # argument list (enclosed brackets) and an optional comment.
    def add_description(description)
      return if ! description
      comment = description.strip
      add_comment(comment) if comment && ! comment.empty?
    end

    # Writing to the comment attribute is the same as adding a description.
    def comment=(description)
      add_description(description)
    end

    # Add a comment to the task.  If a comment alread exists, separate
    # the new comment with " / ".
    def add_comment(comment)
      if @full_comment
        @full_comment << " / "
      else
        @full_comment = ''
      end
      @full_comment << comment
      if @full_comment =~ /\A([^.]+?\.)( |$)/
        @comment = $1
      else
        @comment = @full_comment
      end
    end
    private :add_comment

    # Sets the remote host on which to execute this task
    # Validates and expands the given value.
    # Can be either an uri or host[:port]
    # Examples
    #   task.remote = 'server.com'                # => 'http://server.com:9292'
    #   task.remote = 'server.com:56'             # => 'http://server.com:56'
    #   task.remote = '192.168.1.1'               # => 'http://192.168.1.1:9292'
    #   task.remote = 'https://server.com/rrake'  # => 'https://server.com:9292/rrake'
    def remote=(value)
      if value.nil?
        @remote = nil
        return
      end
      value = value.to_s
      begin
        if value =~ URI::ABS_URI
          r = URI.parse(value)
          r = URI.parse("http://#{value}") unless r.host
        else
          r = URI.parse("http://#{value}")
        end
        raise URI::InvalidURIError unless r.host
      rescue URI::InvalidURIError
        fail ArgumentError, "illegal value: '#{value}'"
      end
      if application.respond_to?(:options)
        r.port = application.options.port unless value =~ /:\d+/
      end
      @remote = r.to_s
      @url = "#{@remote}/api/v1/task/#{URI.escape(name, UNSAFE_ESCAPING_DOT)}"
    end

    def create_remote_task
      raise "can't create remote task, #remote is not set" unless remote
      unless @remote_task_created
        rput "delete"  # Make sure the task does not exist (from previous runs)
        rpost("", :klass => self.class.to_s)
        debug2 "Created remote task: '#{url}'"
        @remote_task_created = true
      end
    end

    # Set the names of the arguments for this task. +args+ should be
    # an array of symbols, one for each argument name.
    def set_arg_names(args)
      @arg_names = args.map { |a| a.to_sym }
    end

    # Return a string describing the internal state of a task.  Useful for
    # debugging.
    def investigation
      begin
        if @override_needed_block
          code = @override_needed_block.source.to_s.inspect
          code = "#{code[0..36]}..." if code.size > 40
          override_text = "overrided: #{code}"
        else
          override_text = "not overrided"
        end
      rescue Exception => e
        override_text = "!!failed to show proc: #{e}"
      end
      result = "------------------------------\n"
      result << "Investigating '#{name=='' ? '<noname>' : name}'\n"
      result << "  class:      #{self.class}\n"
      result << "  invoked:    #{@already_invoked}\n"
      result << "  needed:     #{needed?} (#{override_text})\n"
      result << "  timestamp:  #{timestamp}\n"
      result << "  actions:    #{actions.inspect}\n"
      result << "  conditions: #{conditions.inspect}\n"
      result << "  pre-requisites: \n"
      prereqs = prerequisite_tasks
      prereqs.sort! {|a,b| a.timestamp <=> b.timestamp}
      prereqs.each do |p|
        result << "--#{p.name} (#{p.timestamp})\n"
      end
      latest_prereq = prerequisite_tasks.collect { |pre| pre.timestamp }.max
      result <<  "latest-prerequisite time: #{latest_prereq}\n"
      result << "................................\n\n"
      return result
    end

    # ----------------------------------------------------------------
    # Rake Module Methods
    #
    class << self

      # Clear the task list.  This cause rake to immediately forget all the
      # tasks that have been assigned.  (Normally used in the unit tests.)
      def clear
        Rake.application.clear
      end

      # List of all defined tasks.
      def tasks
        Rake.application.tasks
      end

      # Return a task with the given name.  If the task is not currently
      # known, try to synthesize one from the defined rules.  If no rules are
      # found, but an existing file matches the task name, assume it is a file
      # task with no dependencies or actions.
      def [](task_name)
        Rake.application[task_name]
      end

      # TRUE if the task name is already defined.
      def task_defined?(task_name)
        Rake.application.lookup(task_name) != nil
      end

      # Define a task given +args+ and an option block.  If a rule with the
      # given name already exists, the prerequisites and actions are added to
      # the existing task.  Returns the defined task.
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end

      # Define a rule for synthesizing tasks.
      def create_rule(*args, &block)
        Rake.application.create_rule(*args, &block)
      end

      # Apply the scope to the task name according to the rules for
      # this kind of task.  Generic tasks will accept the scope as
      # part of the name.
      def scope_name(scope, task_name)
        (scope + [task_name]).join(':')
      end

      # Strip conditions from args
      # [{:task3=>[{:task1=>false, :task2=>true}]}] => [{:task3=>[:task1, :task2]}] , {:task1=>false, :task2=>true}
      #
      def strip_conditions(*args) # :nodoc:
        args.flatten!
        #puts "strip_conditions:"
        #print "  args:   "; p args
        if args.last.is_a?(Hash)
          deps = args[-1]
          #print "  deps:   "; p deps
          key, value = deps.map { |k, v| [k,v] }.first
          #print "  key:   "; p key
          #print "  value: "; p value
          if value.is_a?(Array) and value.first.is_a?(Hash)
            #puts "  is array"
            deps = value.first.keys
            cond = value.first
            #print "    deps: "; p deps
            #print "    cond: "; p cond
            args[-1] = {key=>deps}
            return [args, cond]
          end
        end
        [args, {}]
      end

    end # class << Rake::Task
  end # class Rake::Task
end
