
describe Rake do
  
  before :each do
    Rake.clear_sessions true
    Rake.application
  end

  it "Rake.application should set default session" do
    Rake.sessions[Rake::DEFAULT_SESSION].app.should == Rake.application
  end
  
  it "Default session should have timeout nil" do
    Rake.sessions[Rake::DEFAULT_SESSION].timeout.should == nil
  end
  
  it "clear_session should remove sessions" do
    Rake.session_threads.size.should == 1
    Rake.new_session
    Rake.new_session
    Rake.new_session
    Rake.sessions.size.should == 4
    Rake.clear_sessions
    Rake.sessions.size.should == 1
    Rake.session_threads.size.should == 0
    Rake.clear_sessions true
    Rake.sessions.size.should == 0
    Rake.session_threads.size.should == 0
  end
  
  it "set_session should fail if the session doesn't exist" do
    lambda { Rake.set_session 'test' }.should raise_error RuntimeError
  end

  it "set_session should register the current thread in session_threads" do
    t = Thread.new do
      Rake.session_threads.size.should == 1
      Rake.set_session Rake::DEFAULT_SESSION
      Rake.session_threads.size.should == 2
      Rake.session_threads[Thread.current.to_s].should == Rake.get_session
    end
    t.join
    Rake.session_threads.size.should == 2
  end

  it "new_session without arguments should give defaults" do
    sid = Rake.new_session
    sid.class.should == String
    s = Rake.sessions[sid]
    s.app.class.should == Rake::Application
    s.timeout.should == Rake::Session::DEFAULT_TIMEOUT
  end

  it "new_session should accept arguments" do
    s_str = 'test'
    app = Rake::Application.new
    sid = Rake.new_session s_str, 60, app
    sid.should == s_str
    s = Rake.sessions[sid]
    s.app.should == app
    s.timeout.should == 60
  end

  it "new_session twice with same id=DEFAULT_SESSION should not fail" do
    lambda { Rake.new_session DEFAULT_SESSION }.should_not raise_error RuntimeError
    lambda { Rake.new_session DEFAULT_SESSION }.should_not raise_error RuntimeError
  end

  it "new_session twice with same id should fail" do
    s_str = 'test'
    Rake.new_session s_str
    lambda { Rake.new_session s_str }.should raise_error RuntimeError
  end

  it "Rake.application after new+set_session should return a new application" do
    a1 = Rake.application
    Rake.set_session Rake.new_session
    a2 = Rake.application
    a1.class.should == Rake::Application
    a1.class.should == a2.class
    a1.should_not == a2
  end

  it "get_session should return the previously set_session" do
    sid = Rake.new_session
    Rake.set_session sid
    Rake.get_session.should == sid
  end

  it "Rake.application in a new thread should return the same object as the parent thread" do
    a1 = Rake.application
    result = a1
    t = Thread.new { result = Rake.application }
    t.join
    result.should == a1
  end

  it "get_session in a new thread should return nil without set_session first" do
    result = 'session1'
    t = Thread.new { result = Rake.get_session }
    t.join
    result.should == nil
  end
  
  it "get_session in a new thread should return id with set_session first" do
    result = ''
    t = Thread.new { Rake.set_session Rake::DEFAULT_SESSION; result = Rake.get_session }
    t.join
    result.should == Rake::DEFAULT_SESSION
  end

  it "Rake.application and new+set_session in a new thread should return a new app object" do
    a1 = Rake.application
    a2 = a1
    t = Thread.new { Rake.set_session Rake.new_session; a2 = Rake.application }
    t.join
    a1.class.should == a2.class
    a1.should_not == a2
  end
  
  # Testing expire_sessions is time consuming so we test lightly
  # maybe we could test it seperatly with a dedicated task?
  it "expire_sessions should expire a session with timeout 0" do
    s_str = 'test'
    sid = Rake.new_session s_str, 0
    Rake.sessions[sid].timeout.should == 0
    Rake.sessions.size.should == 2
    sleep 1
    Rake.expire_sessions
    Rake.sessions.size.should == 1
  end

  it "expire_sessions should not expire a session with timeout=2 which is touched by Rake.application" do
    s_str = 'test'
    sid = Rake.new_session s_str, 2
    s = Rake.sessions[sid]
    s.timeout.should == 2
    Rake.set_session sid
    sleep 1
    Rake.application
    sleep 1
    Rake.expire_sessions
    Rake.sessions.size.should == 2
  end
  
  it "expire_session: session with using thread should not time out" do
    Rake.session_threads.size.should == 1
    threads = {}
    [0,1,60,nil].each do |timeout|
      s = Rake.new_session "s#{timeout}"
      t = Thread.new(timeout) do |timeout|
        Rake.set_session s
        while true do sleep 1000; end
      end
      threads[timeout] = t
    end
    Rake.session_threads.size.should == 5
    Rake.expire_sessions
    Rake.session_threads.size.should == 5
    threads[0].kill
    Rake.expire_sessions
    Rake.session_threads.size.should == 4
    threads[1].kill
    sleep 1
    Rake.expire_sessions
    Rake.session_threads.size.should == 3
    threads.each_value { |t| t.kill }
    Rake.expire_sessions
    Rake.session_threads.size.should == 1
  end

end
