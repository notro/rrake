#require 'rrake/logging'

module Rake

  # The TaskManager module is a mixin for managing tasks.
  module TaskManager
    include Logging
    include RestClient
    
    # Track the last comment made in the Rakefile.
    attr_accessor :last_description
    alias :last_comment :last_description    # Backwards compatibility

    # Tracks the last remote made in the Rakefile.
    attr_accessor :last_remote

    # Track the last remote with a hostname made in the Rakefile.
    attr_accessor :last_remote_with_host #:nodoc:

    # Used by RestClient as base url
    attr_reader :url # :nodoc:

    def initialize
      super
      @tasks = Hash.new
      @rules = Array.new
      @scope = Array.new
      @last_description = nil
      @last_remote = nil
      @last_remote_with_host = nil
      @url = nil
    end

    def create_rule(*args, &block)
      pattern, arg_names, deps = resolve_args(args)
      pattern = Regexp.new(Regexp.quote(pattern) + '$') if String === pattern
      @rules << [pattern, deps, block]
    end

    def define_task(task_class, *args, &block)
      task_name, arg_names, deps = resolve_args(args)
      task_name = task_class.scope_name(@scope, task_name)
      deps = [deps] unless deps.respond_to?(:to_ary)
      deps = deps.collect {|d| d.to_s }
      task = intern(task_class, task_name)
      task.set_arg_names(arg_names) unless arg_names.empty?
      task.remote = @last_remote if @last_remote
      @last_remote = nil
      if Rake::TaskManager.record_task_metadata
        add_location(task)
        task.add_description(get_description(task))
      end
      task.enhance(deps, &block)
    end

    # Lookup a task.  Return an existing task if found, otherwise
    # create a task of the current type.
    def intern(task_class, task_name)
      @tasks[task_name.to_s] ||= task_class.new(task_name, self)
    end

    # Find a matching task for +task_name+.
    def [](task_name, scopes=nil, remote=nil)
      task_name = task_name.to_s
      self.lookup(task_name, scopes) or
        enhance_with_matching_rule(task_name, 0, remote) or
        synthesize_file_task(task_name, remote) or
        fail "Don't know how to build task '#{task_name}'"
    end

    def synthesize_file_task(task_name, remote=nil)
      remote ||= TaskManager.verify_remote(@last_remote)
      if remote
        return nil unless rget "#{remote}/api/v1/fileexist", :trace => task_name, :file => task_name
      else
        return nil unless File.exist?(task_name)
      end
      @last_remote = remote
      define_task(Rake::FileTask, task_name)
    end

    # Resolve the arguments for a task/rule.  Returns a triplet of
    # [task_name, arg_name_list, prerequisites].
    def resolve_args(args)
      if args.last.is_a?(Hash)
        deps = args.pop
        resolve_args_with_dependencies(args, deps)
      else
        resolve_args_without_dependencies(args)
      end
    end

    # Resolve task arguments for a task or rule when there are no
    # dependencies declared.
    #
    # The patterns recognized by this argument resolving function are:
    #
    #   task :t
    #   task :t, [:a]
    #   task :t, :a                 (deprecated)
    #
    def resolve_args_without_dependencies(args)
      task_name = args.shift
      if args.size == 1 && args.first.respond_to?(:to_ary)
        arg_names = args.first.to_ary
      else
        arg_names = args
      end
      [task_name, arg_names, []]
    end
    private :resolve_args_without_dependencies
    
    # Resolve task arguments for a task or rule when there are
    # dependencies declared.
    #
    # The patterns recognized by this argument resolving function are:
    #
    #   task :t => [:d]
    #   task :t, [a] => [:d]
    #   task :t, :needs => [:d]                 (deprecated)
    #   task :t, :a, :needs => [:d]             (deprecated)
    #
    def resolve_args_with_dependencies(args, hash) # :nodoc:
      fail "Task Argument Error" if hash.size != 1
      key, value = hash.map { |k, v| [k,v] }.first
      if args.empty?
        task_name = key
        arg_names = []
        deps = value
      elsif key == :needs
        task_name = args.shift
        arg_names = args
        deps = value
      else
        task_name = args.shift
        arg_names = key
        deps = value
      end
      deps = [deps] unless deps.respond_to?(:to_ary)
      [task_name, arg_names, deps]
    end
    private :resolve_args_with_dependencies
    
    # If a rule can be found that matches the task name, enhance the
    # task with the prerequisites and actions from the rule.  Set the
    # source attribute of the task appropriately for the rule.  Return
    # the enhanced task or nil of no rule was found.
    def enhance_with_matching_rule(task_name, level=0, remote=nil)
      fail Rake::RuleRecursionOverflowError,
        "Rule Recursion Too Deep" if level >= 16
      @rules.each do |pattern, extensions, block|
        if md = pattern.match(task_name)
          task = attempt_rule(task_name, extensions, block, level, remote)
          return task if task
        end
      end
      nil
    rescue Rake::RuleRecursionOverflowError => ex
      ex.add_target(task_name)
      fail ex
    end

    # List of all defined tasks in this application.
    def tasks
      @tasks.values.sort_by { |t| t.name }
    end

    # List of all the tasks defined in the given scope (and its
    # sub-scopes).
    def tasks_in_scope(scope)
      prefix = scope.join(":")
      tasks.select { |t|
        /^#{prefix}:/ =~ t.name
      }
    end

    # Delete a task. Return whether or not the task existed.
    def delete_task(name)
      ret = @tasks.delete(name.to_s) ? true : false
      debug2 "Deleted task: #{name}" if ret
      ret
    end

    # Clear remote servers currently defined in the tasks.
    def clear_remote_servers
      tasks.each do |task|
        Nestful.put "#{task.remote}/api/v1/clear" if task.remote
      end
    end
    
    # Clear all tasks in this application.
    def clear
      debug "Application cleared"
      clear_remote_servers
      @tasks.clear
      @rules.clear
      @last_remote = nil
      @last_remote_with_host = nil
    end

    # Lookup a task, using scope and the scope hints in the task name.
    # This method performs straight lookups without trying to
    # synthesize file tasks or rules.  Special scope names (e.g. '^')
    # are recognized.  If no scope argument is supplied, use the
    # current scope.  Return nil if the task cannot be found.
    def lookup(task_name, initial_scope=nil)
      initial_scope ||= @scope
      task_name = task_name.to_s
      if task_name =~ /^rake:/
        scopes = []
        task_name = task_name.sub(/^rake:/, '')
      elsif task_name =~ /^(\^+)/
        scopes = initial_scope[0, initial_scope.size - $1.size]
        task_name = task_name.sub(/^(\^+)/, '')
      else
        scopes = initial_scope
      end
      lookup_in_scope(task_name, scopes)
    end

    # Lookup the task name
    def lookup_in_scope(name, scope)
      n = scope.size
      while n >= 0
        tn = (scope[0,n] + [name]).join(':')
        task = @tasks[tn]
        return task if task
        n -= 1
      end
      nil
    end
    private :lookup_in_scope

    # Return the list of scope names currently active in the task
    # manager.
    def current_scope
      @scope.dup
    end

    # Evaluate the block in a nested namespace named +name+.  Create
    # an anonymous namespace if +name+ is nil.
    def in_namespace(name)
      name ||= generate_name
      @scope.push(name)
      ns = NameSpace.new(self, @scope)
      yield(ns)
      ns
    ensure
      @scope.pop
    end

    private
    
    # Add a location to the locations field of the given task.
    def add_location(task)
      loc = find_location
      task.locations << loc if loc
      task
    end
    
    # Find the location that called into the dsl layer.
    def find_location
      locations = caller
      i = 0
      while locations[i]
        return locations[i+1] if locations[i] =~ /rake\/dsl_definition.rb/
        i += 1
      end
      nil
    end
      
    # Generate an anonymous namespace name.
    def generate_name
      @seed ||= 0
      @seed += 1
      "_anon_#{@seed}"
    end

    def trace_rule(level, message)
      puts "#{"    "*level}#{message}" if Rake.application.options.trace_rules
      debug2 message
    end

    # Attempt to create a rule given the list of prerequisites.
    def attempt_rule(task_name, extensions, block, level, remote=nil)
      remote ||= TaskManager.verify_remote(@last_remote)
      sources = make_sources(task_name, extensions)
      prereqs = sources.collect { |source|
        trace_rule level, "Attempting Rule #{task_name} => #{source}#{remote ? ' ('+ remote +')' : ''}"
        if remote and rget "#{remote}/api/v1/fileexist", :trace => task_name, :file => source
          trace_rule level, "(#{task_name} => #{source} ... EXIST as file on #{remote})"
          source
        elsif !remote and File.exist?(source)
          trace_rule level, "(#{task_name} => #{source} ... EXIST as file)"
          source
        elsif Rake::Task.task_defined?(source)
          trace_rule level, "(#{task_name} => #{source} ... EXIST as task)"
          source
        elsif parent = enhance_with_matching_rule(source, level+1, remote)
          trace_rule level, "(#{task_name} => #{source} ... ENHANCE)"
          parent.name
        else
          trace_rule level, "(#{task_name} => #{source} ... FAIL)"
          return nil
        end
      }
      @last_remote = remote
      task = FileTask.define_task({task_name => prereqs}, &block)
      task.sources = prereqs
      task
    end

    # Make a list of sources from the list of file name extensions /
    # translation procs.
    def make_sources(task_name, extensions)
      extensions.collect { |ext|
        case ext
        when /%/
          task_name.pathmap(ext)
        when %r{/}
          ext
        when /^\./
          task_name.ext(ext)
        when String
          ext
        when Proc
          if ext.arity == 1
            ext.call(task_name)
          else
            ext.call
          end
        else
          fail "Don't know how to handle rule dependent: #{ext.inspect}"
        end
      }.flatten
    end


    private 
    
    # Return the current description. If there isn't one, try to find it
    # by reading in the source file and looking for a comment immediately
    # prior to the task definition
    def get_description(task)
      desc = @last_description || find_preceding_comment_for_task(task)
      @last_description = nil
      desc
    end
    
    def find_preceding_comment_for_task(task)
      loc = task.locations.last
      file_name, line = parse_location(loc)
      return nil unless file_name
      comment_from_file(file_name, line)
    end
    
    def parse_location(loc)
      if loc =~ /^(.*):(\d+)/
        [ $1, Integer($2) ]
      else
        nil
      end
    end

    def comment_from_file(file_name, line)
      return if file_name == '(eval)'
      @file_cache ||= {}
      content = (@file_cache[file_name] ||= File.readlines(file_name))
      line -= 2
      return nil unless content[line] =~ /^\s*#\s*(.*)/
      $1
    end

    class << self
      attr_accessor :record_task_metadata
      TaskManager.record_task_metadata = false
      
      def verify_remote(value)
        return nil if value.nil?
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
        r.port = Rake.application.options.port unless value =~ /:\d+/
        r.to_s
      end
    end
  end

end
