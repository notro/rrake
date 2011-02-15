
describe Rake::Application do
  before :each do
    ::Rake.application.clear
  end
  
  describe "#delete_task" do
    it "should return false if task does not exist" do
      ::Rake.application.delete_task(:does_not_exist).should == false
    end
    it "should return true if task exist" do
      task :delete_task
      ::Rake.application.delete_task(:delete_task).should == true
    end
  end
end