
describe "Rake::Task with remote" do
  include CaptureStdout
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    ::Rake::TaskManager.record_task_metadata = true
    TestServer.start
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  after :all do
    ::Rake.application.clear
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all
      puts "--------------------------------------------------------------------"
    end
    ::Rake::TaskManager.record_task_metadata = false
  end
  
  ["task",
   "task1_create",
   "task.1",
   "ns:task",
  ].each { |test|
    it "should create task: #{test}" do
      remote "127.0.0.1"
      t = task test
      t.invoke
      TestServer.msg.should =~ /Created task.*#{test}/
    end
  }
  
  it "should create namespace:task" do
    t = nil
    namespace "namespace" do
      remote "127.0.0.1"
      t = task :task1_create
    end
    t.invoke
    TestServer.msg.should =~ /Created task.*namespace:task1_create/
  end
  
  it "Rake.application.clear should clear remote server" do
    remote "127.0.0.1"
    t = task :task1_clear
    t.invoke
    url = t.url
    ::Rake.application.clear
    expect{ Nestful.get url }.to raise_error Nestful::ResourceNotFound
  end
  
  it "should execute task and print to stdout" do
    remote "127.0.0.1"
    t = task :task1_execute do |t|
      t.fatal "task1_log_message"
      puts "task1_stdout_puts_message"
    end
    out = capture_stdout { 
      t.invoke
    }
    out.should =~ /task1_stdout_puts_message/
    msg = TestServer.msg
    msg.should =~ /FATAL.*task1_log_message/
    msg.should =~ /INFO.*task1_stdout_puts_message/
  end
  
  it "should execute task and print to stderr" do
    remote "127.0.0.1"
    t = task :task2_execute do |t|
      $stderr.puts "task1_stderr_puts_message"
    end
    out = capture_stderr { 
      t.invoke
    }
    out.should =~ /task1_stderr_puts_message/
    msg = TestServer.msg
    msg.should =~ /INFO.*stderr.*task1_stderr_puts_message/
  end
  
  it "should execute task with task arguments" do
    remote "127.0.0.1"
    t = task :task1_arg, [:first_name, :last_name] do |t, args|
      puts "First name is #{args.first_name}"
      puts "Last  name is #{args.last_name}"
    end
    out = capture_stdout { 
      t.invoke "John", "Doe"
    }
    out.should =~ /First name is John\nLast  name is Doe/
  end
  
  it "should get task timestamp" do
    remote "127.0.0.1"
    t = task :task1_timestamp
    t.invoke
    ts = t.timestamp
    ts.should < (Time.now + 1)
    ts.should > (Time.now - 2)
    TestServer.msg.should =~ /INFO.*task1.*#{ts.to_i}/
  end
  
  it "should get task needed?" do
    remote "127.0.0.1"
    t = task :task1_needed
    t.invoke
    t.needed?.should == true
    TestServer.msg.should =~ /needed.*\n.*INFO.*true/
  end
  
  it "should override_needed" do
    remote "127.0.0.1"
    t = task :task1_override_needed
    t.override_needed do 99 end
    t.invoke
    t.needed?.should == 99
  end
  
  it "should pass in environment variables on remote execution" do
    ENV["TEST_RAKE_ENV"] = "123456789"
    remote "127.0.0.1"
    t = task :task_get_env_var do |t|
      puts "-- #{ENV["TEST_RAKE_ENV"]} --"
    end
    out = capture_stdout { 
      t.invoke
    }
    out.should =~ /-- 123456789 --/
    ENV["TEST_RAKE_ENV"] = nil
  end
  
  it "should pass prerequisites" do
    remote "127.0.0.1"
    task :task2_pre
    t = task :task_pre => [:task2_pre] do |t|
      puts "-- #{t.prerequisites.first} --"
    end
    out = capture_stdout { 
      t.invoke
    }
    out.should =~ /-- task2_pre --/
  end

# Rake tests that need tweaking to run  

# test/lib/task_test.rb
# TestTask
  it "test_create" do
    arg = nil
    remote "127.0.0.1"
    t = task(:name) do |task| puts task.name end
    t.name.should == "name"
    t.prerequisites.should == []
    t.needed?.should == true
    out = capture_stdout { 
      t.execute(0)
    }
    out.should == "name\n"
    t.source.should == nil
    t.sources.should == []
    t.locations.size.should == 1
    t.locations.first.should =~/#{Regexp.quote(__FILE__)}/
  end

  it "test_invoke" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2, :t3]) do |t| puts t.name; 3321 end
    t2 = task(:t2) do |t| puts t.name end
    t3 = task(:t3) do |t| puts t.name end
    t1.prerequisites.should == ["t2", "t3"]
    out = capture_stdout { 
      t1.invoke
    }
    out.should == "t2\nt3\nt1\n"
  end

  it "test_invoke_with_circular_dependencies" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2]) do |t| puts t.name; 3321 end
    t2 = task(:t2 => [:t1]) do |t| puts t.name end
    t1.prerequisites.should == ["t2"]
    t2.prerequisites.should == ["t1"]
    expect{ t1.invoke }.to raise_error RuntimeError, /circular dependency.*t1 => t2 => t1/i
  end

  it "test_no_double_invoke" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2, :t3]) do |t| puts t.name; 3321 end
    t2 = task(:t2 => [:t3]) do |t| puts t.name end
    t3 = task(:t3) do |t| puts t.name end
    out = capture_stdout { 
      t1.invoke
    }
    out.should == "t3\nt2\nt1\n"
  end

  it "test_can_double_invoke_with_reenable" do
    remote "127.0.0.1"
    t1 = task(:t1) do |t| puts t.name end
    out = capture_stdout { 
      t1.invoke
    }
    out.should == "t1\n"
    t1.reenable
    out = capture_stdout { 
      t1.invoke
    }
    out.should == "t1\n"
  end

  it "test_multi_invocations" do
    p = proc do |t| puts t.name end
    remote "127.0.0.1"
    task({:t1=>[:t2,:t3]}, &p)
    task({:t2=>[:t3]}, &p)
    task(:t3, &p)
    out = capture_stdout { 
      ::Rake::Task[:t1].invoke
    }
    out.should == "t3\nt2\nt1\n" #    assert_equal ["t1", "t2", "t3"], runs.sort
  end

  it "test_timestamp_returns_now_if_all_prereqs_have_no_times" do
    remote "127.0.0.1"
    a = task :a => ["b", "c"]
    b = task :b
    c = task :c

    # This can't be tested like the original test, because Time.now is accessed in another process.
    time = Time.now
    a.timestamp.should be_within(1).of(time)
  end
  
  
# TestTaskWithArguments
  it "test_arg_list_is_empty_if_no_args_given" do
    remote "127.0.0.1"
    t = task(:t) do |tt, args|
      puts "args is empty" if args.to_hash.empty?
    end
    out = capture_stdout { 
      t.invoke(1, 2, 3)
    }
    out.should =~ /args is empty/
  end

  it "test_tasks_can_access_arguments_as_hash" do
    remote "127.0.0.1"
    t = task :t, :a, :b, :c do |tt, args|
      # Proc#source can't handle {:a=>1}
      hash = Hash.new
      hash[:a] = 1
      hash[:b] = 2
      hash[:c] = 3
      if args.to_hash == hash then
        puts "to_hash" 
      end
      puts "argsa" if args[:a] == 1
      puts "argsb" if args[:b] == 2
      puts "argsc" if args[:c] == 3
      puts "args_a" if args.a == 1
      puts "args_b" if args.b == 2
      puts "args_c" if args.c == 3
    end
    out = capture_stdout { 
      t.invoke(1, 2, 3)
    }
    out.should =~ /to_hash\nargsa\nargsb\nargsc\nargs_a\nargs_b\nargs_c/
  end

  it "test_actions_of_various_arity_are_ok_with_args" do
    remote "127.0.0.1"
    t = task(:t, :x) do
      puts "a"
    end
    t.enhance do | |
      puts "b"
    end
    t.enhance do |task|
      puts "c"
      puts "Task" if task.kind_of? Rake::Task
    end
    t.enhance do |t2, args|
      puts "d"
      puts "-#{t2.name}-"
      hash = Hash.new
      hash[:x] = 1
      puts "to_hash" if args.to_hash == hash
    end
    out = capture_stdout { 
      t.invoke(1)
    }
    out.should =~ /a\nb\nc\nTask\nd\n-t-\nto_hash/
  end
  
  it "test_arguments_are_passed_to_block" do
    remote "127.0.0.1"
    t = task(:t, :a, :b) do |tt, args|
      hash = Hash.new
      hash[:a] = 1
      hash[:b] = 2
      puts "to_hash" if args.to_hash == hash
    end
    out = capture_stdout { 
      t.invoke(1,2)
    }
    out.should =~ /to_hash/
  end

  it "test_extra_parameters_are_ignored" do
    remote "127.0.0.1"
    t = task(:t, :a) do |tt, args|
      puts "args_a" if args.a == 1
      puts "args_b" if args.b.nil?
    end
    out = capture_stdout { 
      t.invoke(1,2)
    }
    out.should =~ /args_a\nargs_b/
  end

  it "test_arguments_are_passed_to_all_blocks" do
    remote "127.0.0.1"
    t = task :t, :a
    task :t do |tt, args|
      puts "argsa" if args[:a] == 1
    end
    task :t do |tt, args|
      puts "argsa" if args[:a] == 1
    end
    out = capture_stdout { 
      t.invoke(1)
    }
    out.should =~ /argsa\nargsa/
  end

  it "test_block_with_no_parameters_is_ok" do
    remote "127.0.0.1"
    t = task(:t) do end
    t.invoke(1, 2)
  end

  it "test_named_args_are_passed_to_prereqs" do
    remote "127.0.0.1"
    pre = task(:pre, :rev) do |t, args| puts args.rev end
    t = task(:t, :name, :rev, :needs => [:pre])
    out = capture_stdout { 
      t.invoke("bill", "1.2")
    }
    out.should == "1.2\n"
  end

  it "test_args_not_passed_if_no_prereq_names" do
    remote "127.0.0.1"
    pre = task(:pre) do |t, args|
      puts "args is empty" if args.to_hash.empty?
      puts args.name.inspect
    end
    t = task(:t, :name, :rev, :needs => [:pre])
    out = capture_stdout { 
      t.invoke("bill", "1.2")
    }
    out.should == "args is empty\nnil\n"
  end

  it "test_args_not_passed_if_no_arg_names" do
    remote "127.0.0.1"
    pre = task(:pre, :rev) do |t, args|
      puts "args is empty" if args.to_hash.empty?
    end
    t = task(:t, :needs => [:pre])
    out = capture_stdout { 
      t.invoke("bill", "1.2")
    }
    out.should == "args is empty\n"
  end
end
