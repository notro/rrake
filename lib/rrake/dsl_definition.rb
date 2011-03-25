# Rake DSL functions.
require 'rrake/file_utils_ext'

module Rake
  module DSL

    # Include the FileUtils file manipulation functions in the top
    # level module, but mark them private so that they don't
    # unintentionally define methods on other objects.
    
    include FileUtilsExt
    private(*FileUtils.instance_methods(false))
    private(*FileUtilsExt.instance_methods(false))

    # Declare a basic task.
    #
    # Example:
    #   task :clobber => [:clean] do
    #     rm_rf "html"
    #   end
    #
    def task(*args, &block)
      args, cond = Rake::Task.strip_conditions(args)
      task = Rake::Task.define_task(*args, &block)
      task.add_conditions cond
      task
    end
    
    
    # Declare a file task.
    #
    # Example:
    #   file "config.cfg" => ["config.template"] do
    #     open("config.cfg", "w") do |outfile|
    #       open("config.template") do |infile|
    #         while line = infile.gets
    #           outfile.puts line
    #         end
    #       end
    #     end
    #  end
    #
    def file(*args, &block)
      Rake::FileTask.define_task(*args, &block)
    end
    
    # Declare a file creation task.
    # (Mainly used for the directory command).
    def file_create(args, &block)
      Rake::FileCreationTask.define_task(args, &block)
    end
    
    # Declare a set of files tasks to create the given directories on
    # demand.
    #
    # Example:
    #   directory "testdata/doc"
    #
    def directory(dir)
      last_remote = Rake.application.last_remote
      Rake.each_dir_parent(dir) do |d|
        Rake.application.last_remote = last_remote
        file_create d do |t|
          mkdir_p t.name if ! File.exist?(t.name)
        end
      end
    end
    
    # Declare a task that performs its prerequisites in
    # parallel. Multitasks does *not* guarantee that its prerequisites
    # will execute in any given order (which is obvious when you think
    # about it)
    #
    # Example:
    #   multitask :deploy => [:deploy_gem, :deploy_rdoc]
    #
    def multitask(args, &block)
      Rake::MultiTask.define_task(args, &block)
    end
    
    # Create a new rake namespace and use it for evaluating the given
    # block.  Returns a NameSpace object that can be used to lookup
    # tasks defined in the namespace.
    #
    # E.g.
    #
    #   ns = namespace "nested" do
    #     task :run
    #   end
    #   task_run = ns[:run] # find :run in the given namespace.
    #
    def namespace(name=nil, &block)
      name = name.to_s if name.kind_of?(Symbol)
      name = name.to_str if name.respond_to?(:to_str)
      unless name.kind_of?(String) || name.nil?
        raise ArgumentError, "Expected a String or Symbol for a namespace name"
      end
      Rake.application.in_namespace(name, &block)
    end
    
    # Declare a rule for auto-tasks.
    #
    # Example:
    #  rule '.o' => '.c' do |t|
    #    sh %{cc -o #{t.name} #{t.source}}
    #  end
    #
    # Note:
    # If the rule is run on a remote task and a proc is used to calculate the name of the source file, the proc is run on the client.
    #
    def rule(*args, &block)
      Rake::Task.create_rule(*args, &block)
    end
    
    # Describe the next rake task.
    #
    # Example:
    #   desc "Run the Unit Tests"
    #   task :test => [:build]
    #     runtests
    #   end
    #
    def desc(description)
      Rake.application.last_description = description
    end
    
    # Make the subsequent task execute on a remote machine
    # If host is not specified, the last remote with a host specified will be used.
    # remote also accepts a block and will set remote for all the contained tasks.
    # Argument: host|ip[:port]
    #
    #  remote "server.com"
    #  file "somefile" do
    #    puts "will run if somefile does not exist on server.com"
    #  end
    #  
    #  remote
    #  task :task do
    #    puts "will execute on server.com"
    #  end
    #
    #  remote "127.0.0.1" do
    #    task :t1 do puts "will execute on 127.0.0.1" end
    #    task :t2 do puts "will execute on 127.0.0.1" end
    #  end
    #  task :t3 do puts "will execute locally" end
    #
    def remote(host=nil)
      if host then
        Rake.application.last_remote = host
        Rake.application.last_remote_with_host = host
      else
        if Rake.application.last_remote_with_host then
          Rake.application.last_remote = Rake.application.last_remote_with_host
        else
          fail ArgumentError, "missing host"
        end
      end
      if block_given?
        global_remote = Rake.application.options.remoteurl
        Rake.application.options.remoteurl = Rake.application.last_remote
        yield
        Rake.application.options.remoteurl = global_remote
      end
    end
    
    # Import the partial Rakefiles +fn+.  Imported files are loaded
    # _after_ the current file is completely loaded.  This allows the
    # import statement to appear anywhere in the importing file, and yet
    # allowing the imported files to depend on objects defined in the
    # importing file.
    #
    # A common use of the import statement is to include files
    # containing dependency declarations.
    #
    # See also the --rakelibdir command line option.
    #
    # Example:
    #   import ".depend", "my_rules"
    #
    def import(*fns)
      fns.each do |fn|
        Rake.application.add_import(fn)
      end
    end

    # Include the Rake DSL commands in the top level Ruby scope.
    def self.include_in_top_scope
      Object.send(:include, Rake::DSL)
    end
  end

  extend FileUtilsExt
end
