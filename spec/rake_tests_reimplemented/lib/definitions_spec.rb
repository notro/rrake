# test/lib/definitions_test.rb


describe "TestDefinitions" do
  include CaptureStdout

  EXISTINGFILE = "testdata/existing"
  
  before :all do
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    rm_f "testdata"
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_task" do
    remote "127.0.0.1"
    task :one => [:two] do |t| t.fatal "done" end
    remote
    task :two
    remote
    task :three => [:one, :two]
    check_tasks(:one, :two, :three)
    TestServer.msg.should =~ /FATAL.*done/
  end

  it "test_file_task" do
    remote "127.0.0.1"
    file "testdata/one" => "testdata/two" do |t| t.fatal "done" end
    remote
    file "testdata/two"
    remote
    file "testdata/three" => ["testdata/one", "testdata/two"]
    check_tasks("testdata/one", "testdata/two", "testdata/three")
    TestServer.msg.should =~ /FATAL.*done/
  end

  it "test_incremental_definitions" do
    remote "127.0.0.1"
    task :t1 => [:t2] do puts "A"; 4321 end
    task :t1 => [:t3] do puts "B"; 1234 end
    task :t1 => [:t3]
    remote
    task :t2
    remote
    task :t3
    out = capture_stdout { 
      ::Rake::Task[:t1].invoke
    }
    out.should == "A\nB\n"
    ::Rake::Task[:t1].prerequisites.should == ["t2", "t3"]
  end

  it "test_implicit_file_dependencies" do
    create_existing_file
    remote "127.0.0.1"
    task :y => [EXISTINGFILE] do |t| t.fatal t.name end
    ::Rake::Task[:y].invoke
    TestServer.msg.should =~ /FATAL.*y/
  end
  
  def check_tasks(n1, n2, n3)
    t = ::Rake::Task[n1]
    t.should be_kind_of ::Rake::Task
    t.name.should == n1.to_s
    (t.prerequisites.collect{|n| n.to_s}).should == [n2.to_s]
    t.invoke
    t2 = ::Rake::Task[n2]
    t2.prerequisites.should == ::Rake::FileList[]
    t3 = ::Rake::Task[n3]
    (t3.prerequisites.collect{|n|n.to_s}).should == [n1.to_s, n2.to_s]
  end
  
  def create_existing_file
    Dir.mkdir File.dirname(EXISTINGFILE) unless
      File.exist?(File.dirname(EXISTINGFILE))
    open(EXISTINGFILE, "w") do |f| f.puts "HI" end unless
      File.exist?(EXISTINGFILE)
  end
end
