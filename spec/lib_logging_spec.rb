
module LogTesting
  def ioout(level)
    io = StringIO.new
    log_add_output Log4r::IOOutputter.new("io_#{level}", io), level
    io
  end
  
  def test_methods(regexp ,&block)
    o = ioout Log4r::ALL
    yield
    o.rewind
    o.read.should =~ regexp
  end
end


describe "Rake::Logging.log_init" do
  include Rake::Logging
  
  attr_accessor :log

  it "should set custom levels" do
    log_init 'test'
    (Log4r.constants & ["DEBUG2", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"]).size.should == 6
  end
  
  it "should return a logger" do
    log_init('test').class.should == Log4r::Logger
  end
  
  it "should set log level to OFF" do
    log_init('test').level.should == Log4r::OFF
  end
end


describe "Rake::Logging.log_add_output" do
  include Rake::Logging
  
  attr_accessor :log

  it "should add an outputter and set the logger level" do
    @log = log_init('test')
    outp = Log4r::IOOutputter.new('io', StringIO.new)
    log_add_output outp, Log4r::ALL
    @log.outputters.should == [outp]
    @log.level.should == Log4r::ALL
  end
end


describe "Rake::Logging.log_context (without name method)" do
  include Rake::Logging
  
  attr_accessor :log

  before :each do
    Thread.current[Rake::RRAKE_LOGCTX] = nil
  end
  
  it "should initially be ''" do
    self.log_context.should == ""
  end
  
  it "when set should return the same" do
    self.log_context = 'testing'
    self.log_context.should == 'testing'
  end
  
end


describe "Rake::Logging.log_context (with name method)" do
  include Rake::Logging
  
  attr_accessor :log, :name
  
  before :all do
    @name = 'testing log_context'
  end
  
  before :each do
    Thread.current[Rake::RRAKE_LOGCTX] = nil
  end
  
  it "should initially be ''" do
    self.log_context.should == ""
  end
  
  it "when set should return the same" do
    self.log_context = 'test'
    self.log_context.should == 'test'
  end
  
  it "should initially be '' in a new thread" do
    ctx = nil
    t = Thread.new { ctx = log_context }
    t.join
    ctx.should == ''
  end
  
  it "when set should be the same in a new thread" do
    t = Thread.new { self.log_context = "thread"; self.log_context.should == "thread" }
    t.join
  end
  
  it "setting context in a new thread should not affect the parent" do
    self.log_context = "parent"
    t = Thread.new { self.log_context.should == ""; self.log_context = "thread"; self.log_context.should == "thread" }
    t.join
    self.log_context.should == "parent"
  end
  
end


describe "Rake::Logging log methods" do
  include Rake::Logging
  include LogTesting
  
  attr_accessor :log, :name
  
  before :all do
    @name = 'testing log methods'
  end
  
  before :each do
    @log = log_init 'test'
  end
  
  it "should log debug2 message" do
    test_methods(/ DEBUG2 .* low level/) do
      debug2 "low level message"
    end
  end

  it "should log debug message" do
    test_methods(/ DEBUG .* low level/) do
      debug "low level message"
    end
  end

  it "should log info message" do
    test_methods(/ INFO .* low level/) do
      info "low level message"
    end
  end

  it "should log warn message" do
    test_methods(/ WARN .* low level/) do
      warn "low level message"
    end
  end

  it "should log error message" do
    test_methods(/ ERROR .* low level/) do
      error "low level message"
    end
  end

  it "should log fatal message" do
    test_methods( / FATAL .* low level/) do
      fatal "low level message"
    end
  end

end


describe "Rake::Logging.log_context" do
  include Rake::Logging
  include LogTesting
  
  attr_accessor :log, :name
  
  before :all do
    @name = 'testing log methods'
  end
  
  before :each do
    @log = log_init 'test'
  end
  
  it "should show up in log output" do
    o = ioout Log4r::ALL
    info "ctx test"
    o.rewind
    o.read.should =~ / INFO.*\[\].*ctx test/
    self.log_context = "Ctx"
    error "ctx2 test"
    o.rewind
    o.read.should =~ / ERROR.*\[Ctx\].*ctx2 test/
    t = Thread.new { self.log_context.should == ""; self.log_context = "thread"; fatal "ctx3 test" }
    t.join
    o.rewind
    o.read.should =~ / FATAL.*\[thread\].*ctx3 test/
  end
end


describe Rake::Task do
  
  before :all do
    Rake.application = nil
    @io = StringIO.new
    Rake.application.log_add_output Log4r::IOOutputter.new("io", @io), Log4r::ALL
  end
  
  before :each do
    Rake.application.clear
    @io.string = ""
  end
  
  it "log_context should be set differently for a task depending upon it's place in the chain of invocation" do
    t = task :one => [:two, :common]
    task :two => :common
    task :common => :three
    task :three
    t.invoke
    @io.rewind
    log = @io.read
    log.should include "[one]"
    log.should include "[one => two]"
    log.should include "[one => two => common]"
    log.should include "[one => two => common => three]"
    log.should include "[one => common]"
  end
end
