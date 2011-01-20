
describe Rake::DSL do

  before :each do
    Rake.application.clear
  end
  
  it "remote without host and without previous remote, should fail" do
    lambda { remote }.should raise_error ArgumentError
  end
  
  ["server.com", "server.com:4567", "192.168.1.1", "192.168.1.1:4567"].each do |host|
    it "remote should accept #{host}" do
      remote host
      Rake.application.last_remote.should == host
      Rake.application.last_remote_with_host.should == host
    end
  end
  
  it "Rake.application.clear should clear last_remote_with_host" do
    host = "server.com"
    remote host
    Rake.application.last_remote_with_host.should == host
    Rake.application.clear
    Rake.application.last_remote_with_host.should == nil
  end
  
  it "should accept empty remote after remote with host" do
    host = "server.com"
    remote host
    Rake.application.last_remote.should == host
    Rake.application.last_remote_with_host.should == host
    remote
    Rake.application.last_remote.should == host
    Rake.application.last_remote_with_host.should == host
  end
end