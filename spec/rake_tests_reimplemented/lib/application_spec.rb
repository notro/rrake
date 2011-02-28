# test/lib/application_test.rb


describe "TestApplication" do
  include InEnvironment
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    TestServer.start
    @app = ::Rake::Application.new
    @app.options.rakelib = []
  end
  
  after :all do
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all if ENV['DEBUG']
      puts "--------------------------------------------------------------------"
    end
    rm_f "testdata"
  end
  
  before :each do
    @app.clear
    TestServer.msg
  end
  
  xit "test_building_imported_files_on_demand" do
    mock = flexmock("loader")
    mock.should_receive(:load).with("x.dummy").once
    mock.should_receive(:make_dummy).with_no_args.once
    @app.instance_eval do
      intern(Rake::Task, "x.dummy").enhance do mock.make_dummy end
        add_loader("dummy", mock)
      add_import("x.dummy")
      load_imports
    end
  end
  
  xit "test_good_run" do
    ARGV.clear
    ARGV << '--rakelib=""'
    ARGV << '--log'
    ARGV << 'stderr:debug2'
    @app.options.silent = true
    @app.last_remote = "127.0.0.1"
    @app.instance_eval do
      intern(::Rake::Task, "default").enhance do |t| puts "-test_good_run-" end
    end
    in_environment("PWD" => "test/data/default") do
      @out = capture_stdout {  @app.run }
    end
    @out.should == "-test_good_run-\n"
  end
end
