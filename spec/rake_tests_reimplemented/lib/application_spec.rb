# test/lib/application_test.rb


describe "TestApplication" do
  include CaptureStdout
  include InEnvironment
  
  before :all do
    TestServer.start
    @app = ::Rake::Application.new
    @app.options.rakelib = []
  end
  
  after :all do
    rm_f "testdata"
  end
  
  before :each do
    @app.clear
    TestServer.msg
  end
  
  it "test_good_run" do
    ARGV.clear
    ARGV << '--rakelib=""'
    @app.options.silent = true
    @app.instance_eval do
      t = intern(::Rake::Task, "default")
      t.remote = "127.0.0.1"
      t.enhance do |t| puts "-test_good_run-"; t.fatal "-test_good_run_log_message-" end
    end
    in_environment("PWD" => "test/data/default") do
      @out = capture_stdout {  @app.run }
    end
    @out.should == "-test_good_run-\n"
    TestServer.msg.should =~/FATAL.*-test_good_run_log_message-/
  end
end
