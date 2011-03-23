require "test/filecreation"


describe "TestFileTask reimplemented" do
  include FileCreation
  
  before :all do
    ::Rake::Task.clear
    ::Rake.rm_rf "testdata", :verbose=>false
    TestServer.start
  end
  
  after :all do
    FileUtils.rm_f "testdata"
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_file_times_old_depends_on_new" do
    create_timed_files(::FileCreation::OLDFILE, ::FileCreation::NEWFILE)

    remote "127.0.0.1"
    t1 = ::Rake.application.intern(::Rake::FileTask,::FileCreation::OLDFILE).enhance([::FileCreation::NEWFILE])
    remote
    t2 = ::Rake.application.intern(::Rake::FileTask, ::FileCreation::NEWFILE)
    t2.needed?.should == false
    preq_stamp = t1.prerequisites.collect{|t| ::Rake::Task[t].timestamp}.max
    t2.timestamp.should == preq_stamp
    t1.timestamp.should < preq_stamp
    t1.needed?.should == true
  end

  it "test_file_depends_on_task_depend_on_file" do
    create_timed_files(::FileCreation::OLDFILE, ::FileCreation::NEWFILE)

    remote "127.0.0.1"
    file ::FileCreation::NEWFILE => [:obj] do |t| t.fatal t.name end
    remote
    task :obj => [::FileCreation::OLDFILE] do |t| t.fatal t.name end
    remote
    file ::FileCreation::OLDFILE           do |t| t.fatal t.name end

    ::Rake::Task[:obj].invoke
    ::Rake::Task[::FileCreation::NEWFILE].invoke
    TestServer.msg.should_not =~ /FATAL.*#{::FileCreation::NEWFILE}/
  end
end


describe "TestDirectoryTask reimplemented" do
  before :all do
    ::Rake.rm_rf "testdata", :verbose=>false
  end
  
  after :all do
    ::Rake.rm_rf "testdata", :verbose=>false
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_directory" do
    ::Rake::TaskManager.record_task_metadata = true
    desc "DESC"
    remote "127.0.0.1"
    directory "testdata/a/b/c"
    ::Rake::Task["testdata"].class.should ==       ::Rake::FileCreationTask
    ::Rake::Task["testdata/a"].class.should ==     ::Rake::FileCreationTask
    ::Rake::Task["testdata/a/b/c"].class.should == ::Rake::FileCreationTask
    ::Rake::Task["testdata"].comment.should ==       nil
    ::Rake::Task["testdata/a/b/c"].comment.should == "DESC"
    ::Rake::Task["testdata/a/b"].comment.should ==   nil
    verbose(false) {
      ::Rake::Task["testdata/a/b"].invoke
    }
    File.exist?("testdata/a/b").should ==   true
    File.exist?("testdata/a/b/c").should == false
    ::Rake::TaskManager.record_task_metadata = false
  end

  if ::Rake::Win32.windows?
    it "test_directory_win32" do
      ::Rake::TaskManager.record_task_metadata = true
      desc "WIN32 DESC"
      FileUtils.mkdir_p("testdata")
      Dir.chdir("testdata") do
        remote "127.0.0.1"
        directory 'c:/testdata/a/b/c'
        ::Rake::Task['c:/testdata'].class.should ==       ::Rake::FileCreationTask
        ::Rake::Task['c:/testdata/a'].class.should ==     ::Rake::FileCreationTask
        ::Rake::Task['c:/testdata/a/b/c'].class.should == ::Rake::FileCreationTask
        ::Rake::Task['c:/testdata'].comment.should ==       nil
        ::Rake::Task['c:/testdata/a/b/c'].comment.should == "WIN32 DESC"
        ::Rake::Task['c:/testdata/a/b'].comment.should ==   nil
        verbose(false) {
          ::Rake::Task['c:/testdata/a/b'].invoke
        }
        File.exist?('c:/testdata/a/b').should ==   true
        File.exist?('c:/testdata/a/b/c').should == false
      end
      ::Rake::TaskManager.record_task_metadata = false
    end
  end
end
