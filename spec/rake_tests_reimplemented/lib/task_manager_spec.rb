# test/lib/task_manager_test.rb


describe "TestTaskManager" do
  before :all do
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    if false
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all if ENV['DEBUG']
      puts "--------------------------------------------------------------------"
    end
    rm_f "testdata"
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  xit "test_correctly_scoped_prerequisites_are_invoked" do
    @tm = ::Rake::Application.new
    @tm.last_remote = "127.0.0.1"
    @tm.define_task(::Rake::Task, :z) #do puts "top z" end
puts "\n\nurl: #{@tm['z'].url}\n\n"
puts TestServer.msg
    @tm.in_namespace("a") do
      @tm.define_task(::Rake::Task, :z) do puts "next z" end
      @tm.define_task(::Rake::Task, :x => :z)
    end

    out = capture_stdout { 
    @tm["a:x"].invoke
    }
    out.should == "next z\n"
  end
end
