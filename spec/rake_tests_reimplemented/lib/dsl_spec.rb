# test/lib/dsl_test.rb


describe "DslTest" do
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all if ENV['DEBUG']
      puts "--------------------------------------------------------------------"
    end
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  xit "test_dsl_toplevel_when_require_rake_dsl" do
    assert_nothing_raised {
      ruby '-I./lib', '-rrrake/dsl', '-e', 'task(:x) { }', :verbose => false
    }
  end
end
