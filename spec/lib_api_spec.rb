
describe Rake::API do
  include CaptureStdout
  include InEnvironment
  include CommandHelp
  include ::Rake::RestClient
  
  attr_reader :url
  attr_reader :log_context
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    @log_context = "logging => lib_api_spec"
    TestServer.start
    @url = "http://127.0.0.1:#{::Rake.application.options.port}/api/v1/"
  end
  
  before :each do
    rput "clear"
    TestServer.msg
  end
  
  after :all do
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all
      puts "--------------------------------------------------------------------"
    end
  end
  
  it "should be able to get tasks" do
    response = rget "tasks"
    response.should == []
  end

  it "should fail to get task that doesn't exist" do
    lambda { rget("task/task1") }.should raise_error Nestful::ResourceNotFound
  end

  it "create task without klass should fail" do
    lambda { rpost("task/task1") }.should raise_error Nestful::BadRequest
  end
  
  it "should create task" do
    response = rpost("task/task1", :klass => ::Rake::Task.to_s)
    rget("task/task1").include?(response).should == true
  end
  
  it "should enhance task with action" do
    t = task :task_a do |t|
      puts "task_a_std_out_puts_message"
    end
    rpost("task/#{t.name}", {:klass => t.class.to_s})
    rpost("task/#{t.name}/enhance", {:block => t.actions.first.to_json})
    rget("task/#{t.name}/actions").first.should include "task_a_std_out_puts_message"
  end
  
  it "should execute task" do
    t = task :task1 do |t|
      t.fatal "task1_log_message"
      puts "task1_std_out_puts_message"
      $stderr.puts "task1_stderr_puts_message"
    end
    rpost("task/#{t.name}", {:klass => t.class.to_s})
    rpost("task/#{t.name}/enhance", {:block => t.actions.first.to_json})
    output = rput("task/#{t.name}/execute")
    output.should == [["stdout", "task1_std_out_puts_message\n"], ["stderr", "task1_stderr_puts_message\n"]]
    TestServer.msg.should =~ /FATAL.*task1_log_message/
  end
  
  it "should get task timestamp" do
    rpost("task/timestamptask", {:klass => ::Rake::Task.to_s})
    unix_time = rget("task/timestamptask/timestamp")
    Time.at(unix_time).should < (Time.now + 1)
    Time.at(unix_time).should > (Time.now - 2)
  end
  
  it "should get task needed?" do
    rpost("task/task", {:klass => ::Rake::Task.to_s})
    needed = rget("task/task/needed")
    needed.should == true
  end
  
  it "should be able to override_needed" do
    t = task :task1
    t.override_needed do 99 end
    rpost("task/#{t.name}", {:klass => t.class.to_s})
    r = rpost("task/task1/override_needed", {:block => t.override_needed_block.to_json})
    r.should include "99"
    needed = rget("task/task1/needed")
    needed.should == 99
  end
  
  it "investigation should work" do
    rpost("task/task1", {:klass => ::Rake::Task.to_s})
    msg = rget("task/task1/investigation")
    msg.should =~/Investigating.*task1/
  end
  
  it "delete_task should return false if the task does not exist" do
    rput("task/task_does_not_exist/delete").should == false
  end
  
  it "delete_task should return true if the task exist" do
    rpost("task/task_do_exist", {:klass => ::Rake::Task.to_s})
    rput("task/task_do_exist/delete").should == true
  end

end
