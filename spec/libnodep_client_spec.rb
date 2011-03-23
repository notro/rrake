require 'rack'

# This rack app just returns some of what it is given
class RackServer
  def call(env)
    return [404, {"Content-Type" => "application/text"}, "404 not found"] if env["REQUEST_URI"] =~ /does_not_exist/
    env2 = {}
    ["CONTENT_TYPE", "HTTP_ACCEPT", "REQUEST_PATH", "REQUEST_URI", "REQUEST_METHOD", "QUERY_STRING"].each do |param|
      env2[param] = env[param]
    end
    env2["body"] = ::ActiveSupport::JSON.decode env["rack.input"].read
    [200, {"Content-Type" => "application/json"}, ::ActiveSupport::JSON.encode(env2)]
  end
end


describe ::Rake::RestClient do
  include ::Rake::RestClient
  
  attr_reader :url
  attr_reader :log_context
  
  # Simulate error log method for failure test
  def error msg
    @error = msg
  end
  
  before :all do
    @error = nil
    @log_context = "logging => context"
    @escaped_log_context = ::CGI::escape self.log_context
    @url = "http://localhost:#{::Rake.application.options.port + 1}"
    current_verbose = $VERBOSE
    $VERBOSE = false
    @srvlog = ::Log4r::Logger.new "resttest"
    @srvlog.level = ::Log4r::ALL
    @srvlogio = StringIO.new
    @srvlog.add ::Log4r::IOOutputter.new 'stdout', @srvlogio
    $VERBOSE = current_verbose
    @srvthr = Thread.new do
      @srv = ::Rack::Server.new
      @srv.options[:Port] = ::Rake.application.options.port + 1
      @srv.options[:Logger] = @srvlog
      @srv.options[:server] = 'webrick'
      @srv.options[:environment] = 'test'
      @srv.app = ::RackServer.new
      @srv.middleware.merge!( 'test' => [lambda {|server| server.server.name =~ /CGI/ ? nil : [::Rack::LoggingLogger, @srvlog] }] )
      @srv.start
    end
    timeout = 0
    msg = ''
    while msg !~ /pid/
      sleep 0.1
      @srvlogio.rewind
      msg = @srvlogio.read
      timeout += 1
      fail "timeout, could not start server" if timeout > 300
    end
  end
  
  after :all do
    if false
      puts "\n\nServer log:"
      @srvlogio.rewind
      puts @srvlogio.read
      puts "--------------------------------------------------------------------"
    end
    @srv.server.shutdown
    while @srvthr.alive?
      sleep 0.1
    end
  end
  
  it "should log error message on failure" do
    expect{ rget "does_not_exist" }.to raise_error Nestful::ResourceNotFound
    @error.should =~ /does_not_exist.*404/
  end
  
  [["/", {}, [/./]],
   ["tasks", {}, [/tasks/]],
   ["tasks/task1/needed", {}, [/tasks\/task1\/needed/]],
   ["/", {:test => 5}, [/test=5/]],
   ["/", {:test => "5"}, [/test=5/]],
   ["/d/e/f", {:test => "a b c"}, [/test=a\+b\+c/]],
  ].each do |test|

    it "rget #{test[0]}" do
      r = rget "#{test[0]}", test[1]
      r["REQUEST_METHOD"].should == "GET"
      r["REQUEST_URI"].should match test[0]
      r["HTTP_ACCEPT"].should =~ /application\/json/
      r["body"].should == false
      r["QUERY_STRING"].should include "trace=#{@escaped_log_context}"
      test[2].each do |t|
        r["REQUEST_URI"].should =~ t
      end
    end

  end
  
  [["/", {}],
   ["", {}],
   ["tasks", {}],
   ["/", {:test => 5}],
   ["/tasks", {:test => 5}],
   ["/", {:test => "5"}],
   ["/d/e/f", {:test => "a b c"}],
  ].each do |test|

    it "rpost #{test[0]}" do
      r = rpost "#{test[0]}", test[1].dup
      r["REQUEST_METHOD"].should == "POST"
      r["REQUEST_URI"].should match test[0]
      r["CONTENT_TYPE"].should == "application/json"
      r["body"]["trace"].should == self.log_context
      test[1].each do |k,v|
        r["body"][k.to_s].should == v
      end
    end

  end
  
  [["/", {}],
   ["tasks", {}],
   ["/", {:test => 5}],
   ["/tasks", {:test => 5}],
   ["/", {:test => "5"}],
   ["/d/e/f", {:test => "a b c"}],
  ].each do |test|

    it "rput #{test[0]}" do
      r = rput "#{test[0]}", test[1]
      r["REQUEST_METHOD"].should == "PUT"
      r["REQUEST_URI"].should match test[0]
      r["CONTENT_TYPE"].should == "application/json"
      r["body"]["trace"].should == self.log_context
      test[1].each do |k,v|
        r["body"][k.to_s].should == v
      end
    end

  end
  
end