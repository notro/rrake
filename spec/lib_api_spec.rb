
describe Rake::API do
  include CaptureStdout
  include InEnvironment
  include CommandHelp
  
  def get(rel_url, params={})
    params.merge! :trace => @ctx
    Nestful.get("#{@url}/#{rel_url}", :format => :json, :params => params)
  end
  
  def put(rel_url, params={})
    params.merge! :trace => @ctx
    Nestful.put("#{@url}/#{rel_url}", :format => :json, :params => params)
  end
  
  def post(rel_url, params={})
    params.merge! :trace => @ctx
    Nestful.post("#{@url}/#{rel_url}", :format => :json, :params => params)
  end
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    @ctx = "lib_api_spec"
    @srv = TestRakeServer.new
    @url = "http://127.0.0.1:#{::Rake.application.options.port}/api/v1"
  end
  
  before :each do
    put "clear"
    @srv.logfile.read
  end
  
  after :all do
    if @verbose
      puts "\n\n#{@srv.logfile.path}"
      @srv.logfile.rewind
      puts @srv.logfile.read
      puts "--------------------------------------------------------------------"
    end
    @srv.shutdown
  end
  
  it "should be able to get tasks" do
    response = get "tasks"
    response.should == []
  end

  it "should fail to get task that doesn't exist" do
    lambda { get("task/task1") }.should raise_error Nestful::ResourceNotFound
  end

  it "create task without klass should fail" do
    lambda { post("task/task1") }.should raise_error Nestful::BadRequest
  end
  
  it "should create task" do
    response = post("task/task1", :klass => Marshal.dump(Rake::Task))
    get("task/task1").include?(response).should == true
  end
  
  it "should execute task" do
    t = task :task1 do |t|
      t.fatal "task1_log_message"
      puts "task1_puts_message"
    end
    post("task/#{t.name}", {:klass => Marshal.dump(t.class), :block => Marshal.dump(t.actions.first)})
    output = put("task/#{t.name}/execute")
    output.should =~ /task1_puts_message/
    @srv.logfile.read.should =~ /FATAL.*task1_log_message/
  end
  
  it "should get task timestamp" do
    post("task/timestamptask", {:klass => Marshal.dump(Rake::Task)})
    unix_time = get("task/timestamptask/timestamp")
    Time.at(unix_time).should < (Time.now + 1)
    Time.at(unix_time).should > (Time.now - 2)
  end
  
  it "should get task needed?" do
    post("task/task", {:klass => Marshal.dump(Rake::Task)})
    needed = get("task/task/needed")
    needed.should == true
  end
  
  it "should be able to override_needed" do
    t = task :task1
    t.override_needed { false }
    post("task/#{t.name}", {:klass => Marshal.dump(t.class)})
    post("task/task1/override_needed", {:block => Marshal.dump(t.instance_variable_get("@override_needed_block"))})
    needed = get("task/task1/needed")
    needed.should == false
  end
  
  it "investigation should work" do
    post("task/task1", {:klass => Marshal.dump(Rake::Task)})
    msg = get("task/task1/investigation")
    msg.should =~/Investigating.*task1/
  end

end


# response = Nestful.post("#{@url}/session", :format => :json, :params => {:trace => self.log_context, })
# response = Nestful.post(@url, :format => :json, :params => {:trace => self.log_context, :klass => Marshal.dump(self.class), :prerequisites => @prerequisites, :conditions => @conditions})
