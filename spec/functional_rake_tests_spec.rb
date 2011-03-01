require 'rrake/testtask'


# We need a loader that can skip tests
module Rake
  class TestTask
    def rake_loader # :nodoc:
      $LOAD_PATH << File.dirname(rake_lib_dir)
      find_file('spec/remote_rake_test_loader') or
        fail "unable to find remote rake test loader"
    end
  end
end


module TestFiles
  # test/lib/rules_test.rb is implemented as spec
  EXCLUDE = ['test/lib/package_task_test.rb', 'test/lib/rdoc_task_test.rb', 'test/lib/rules_test.rb']
  UNIT = FileList['test/lib/*_test.rb'] - EXCLUDE
  FUNCTIONAL = FileList['test/functional/*_test.rb'] - EXCLUDE
  CONTRIB = FileList['test/contrib/test*.rb'] - EXCLUDE
  TOP = FileList['test/*_test.rb'] - EXCLUDE
  ALL = TOP + UNIT + FUNCTIONAL + CONTRIB
end


describe "Rake test cases running as remote tasks" do

  before :all do
    TestServer.start
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  after :all do
    ENV['RAKE_REMOTE'] = nil  
    ::Rake.application.clear
    if false
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all
      puts "--------------------------------------------------------------------"
    end
  end
  
  it "should run" do
    ::Rake::TestTask.new(:rake_standard) do |t|
      t.test_files = TestFiles::ALL
      t.libs << "."
      t.warning = true if $-w
#      t.verbose = true
    end
    t = ::Rake::Task[:rake_standard]
    ENV['RAKE_REMOTE'] = "http://127.0.0.1:9292"
    t.invoke
  end
end
