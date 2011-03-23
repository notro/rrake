
describe "Rake::FileTask with remote" do
  include CaptureStdout
  
  def create_dir(dirname)
    FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
    dirname
  end

  def create_file(name)
    create_dir(File.dirname(name))
    FileUtils.touch(name) unless File.exist?(name)
    name
  end

  def delete_file(name)
    File.delete(name) rescue nil
  end

  before :all do
    FileUtils.rm_rf 'testdata/server'
    TestServer.start
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  after :all do
    FileUtils.rm_rf 'testdata/server'
    ::Rake.application.clear
  end
  
  it "should not execute if file exist" do
    remote "127.0.0.1"
    t = file create_file "testdata/server/file1" do |t|
      t.fatal "should_not_run"
    end
    t.invoke
    t.needed?.should == false
    TestServer.msg.should_not match(/FATAL.*should_not_run/)
  end
  
  it "should execute if file do not exist" do
    remote "127.0.0.1"
    t = file "testdata/server/file_do_not_exist" do |t|
      t.fatal "should_run"
    end
    t.invoke
    t.needed?.should == true
    TestServer.msg.should match(/FATAL.*should_run/)
  end
  
  it "#timestamp should return correct time if file exist" do
    remote "127.0.0.1"
    t = file create_file "testdata/server/file2"
    t.invoke
    t.timestamp.to_i.should == File.mtime("testdata/server/file2").to_i
  end
  
  it "#timestamp should return correct time if file do not exist" do
    remote "127.0.0.1"
    t = file "testdata/server/file_do_not_exist"
    t.invoke
    t.timestamp.should == ::Rake::EARLY
  end
  
end
