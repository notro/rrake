# test/lib/task_manager_test.rb


describe "TestTaskManager" do
  before :all do
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
  end
  
  before :each do
    ::Rake.application.clear
    @runs = nil
    TestServer.msg
  end
  
  def runs
    return @runs unless @runs.nil?
    @runs = []
    @msg = TestServer.msg
    fatal = @msg.lines.select { |l| l.include? "FATAL"}
    fatal.each { |f| m = f.match(/--(.+)--/); @runs << m[1] if m }
    @runs
  end
  
  it "test_correctly_scoped_prerequisites_are_invoked" do
    remote = "127.0.0.1:#{::Rake.application.options.port}"
    @tm = ::Rake::Application.new
    @tm.last_remote = remote
    @tm.define_task(::Rake::Task, :z) do |t| t.fatal "--top z--" end
    @tm.in_namespace("a") do
      @tm.last_remote = remote
      @tm.define_task(::Rake::Task, :z) do |t| t.fatal "--next z--" end
      @tm.last_remote = remote
      @tm.define_task(::Rake::Task, :x => :z)
    end
    @tm["a:x"].invoke
    runs.should == ["next z"]
  end
end
