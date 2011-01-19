require 'rrake/win32'


describe 'rrake commandline' do
  include CaptureStdout
  include InEnvironment
  include CommandHelp
  
  before :all do
    Rake.mkdir_p "testdata", :verbose=>false
  end
  
  after :all do
    Rake.rm_f "testdata", :verbose=>false
  end
  
  it '--debug rake' do
    @out = capture_stdout { 
      command_line('--debug', 'rake')
      @app.options.debug.should == true
      set_trace_func nil
    }
    @out.should include 'Rake::Application'
    @out.should_not include 'c-call'
  end
  
  it '--debug all' do
    @out = capture_stdout { 
      command_line('--debug', 'all')
      @app.options.debug.should == true
      set_trace_func nil
    }
    @out.should include 'OptionParser'
    @out.should include 'c-call'
  end
  
  it '--log with no option should fail' do
    lambda {  command_line('--log') }.should raise_error OptionParser::MissingArgument
  end
  
  it '--log with missing level option should fail' do
    lambda {  command_line('--log', 'stdout') }.should raise_error RuntimeError
  end
  
  it '--log with bad level should fail' do
    lambda {  command_line('--log', 'stdout:bad') }.should raise_error RuntimeError
  end
  
  it '--log should accept stdout' do
    lambda {  command_line('--log', 'stdout:info') }.should_not raise_error RuntimeError
    @app.log.outputters.first.class.should == Log4r::StdoutOutputter
  end
  
  it '--log should accept stderr' do
    lambda {  command_line('--log', 'stderr:info') }.should_not raise_error RuntimeError
    @app.log.outputters.first.class.should == Log4r::StderrOutputter
  end
  
  if !Rake::Win32.windows?
  it '--log should accept syslog' do
    lambda {  command_line('--log', 'syslog:info') }.should_not raise_error RuntimeError
    @app.log.outputters.first.class.should == Log4r::SyslogOutputter
  end
  end
  
  it '--log should accept filename' do
    Rake.rm_rf "testdata/rrake.log", :verbose=>false
    lambda {  command_line('--log', 'testdata/rrake.log:info') }.should_not raise_error RuntimeError
    @app.log.outputters.first.class.should == Log4r::FileOutputter
  end
  
  it '--log should not accept filename in unwritable directory' do
    lambda {  command_line('--log', 'none_existing_directory/rrake.log:info') }.should raise_error RuntimeError
  end
  
  it '--log should accept multiple destinations' do
    Rake.rm_rf "testdata/rrake.log", :verbose=>false
    lambda {  command_line('--log', 'stdout:info,stderr:error,testdata/rrake.log:info') }.should_not raise_error RuntimeError
    @app.log.outputters.collect { |o| o.class }.should include(Log4r::StdoutOutputter, Log4r::StderrOutputter, Log4r::FileOutputter)
  end
  
  it '--port should not accept illegal number' do
    in_environment do
      lambda {  command_line('--port', '0') }.should raise_error RuntimeError
    end
    in_environment do
      lambda {  command_line('--port', 'string') }.should raise_error RuntimeError
    end
    in_environment do
      lambda {  command_line('--port', '66000') }.should raise_error RuntimeError
    end
  end

  it '--port should accept 9000' do
    in_environment do
      command_line('--port', '9000')
      @app.options.port.should == 9000
    end
  end

  it 'Rack should parse arguments after --server' do
    in_environment do
      @out = capture_stdout {
        lambda {  command_line('--server', '-h') }.should raise_error SystemExit
      }
      @out.should =~/rackup/
    end
  end
end
