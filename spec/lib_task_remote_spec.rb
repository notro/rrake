
describe "Rake::Task with remote" do
  include CaptureStdout
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
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
  
  it "execute task currently fails with task arguments" do
    remote "127.0.0.1"
    t = task :task1_fail do |t|
      false
    end
    t.invoke
    expect{ t.execute :a=>true }.to raise_error RuntimeError
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
  
end
