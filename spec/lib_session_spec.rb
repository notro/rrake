
describe Rake::Session do
  
  it 'should set values' do
    s = Rake::Session.new Rake::Application.new, 100
    s.timeout.should == 100
    s.app.class.should == Rake::Application
  end
  
  it 'should set default timeout' do
    s = Rake::Session.new Rake::Application.new
    s.timeout.should == Rake::Session::DEFAULT_TIMEOUT
  end
  
  it 'should set last_access on creation' do
    t = Time.now
    sleep 0.01
    s = Rake::Session.new Rake::Application.new
    s.last_access.should > t
    sleep 0.01
    s.last_access.should < Time.now
  end
  
  it 'should be able to set last_access' do
    s = Rake::Session.new Rake::Application.new
    t = Time.now
    s.last_access = t
    s.last_access.should == t
  end
  
end
