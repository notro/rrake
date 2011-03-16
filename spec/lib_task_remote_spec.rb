
describe "Rake::Task with remote" do
  include CaptureStdout
  include ::Rake::DSL
  
  before :all do
    TestServer.start
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  after :all do
    ::Rake.application.clear
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
    TestServer.msg.should =~ /INFO.*task1_timestamp.*#{Regexp.escape ts.iso8601(3)}/
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
  
  it "should set remote on all tasks inside remote block" do
    ::Rake.application.options.remoteurl.should == nil
    remote "127.0.0.1" do
      @t1 = task :t1
      @t2 = task :t2
    end
    t3 = task :t3
    @t1.remote.should =~/127.0.0.1/
    @t2.remote.should =~/127.0.0.1/
    t3.remote.should == nil
  end
end
