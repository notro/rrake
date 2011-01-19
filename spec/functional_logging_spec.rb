require 'rrake/win32'

describe Rake::Logging do
  include CaptureStdout
  include InEnvironment
  include CommandHelp
  
  before :all do
    Rake.mkdir_p "testdata", :verbose=>false
  end
  
  after :all do
    Rake.rm_f "testdata", :verbose=>false
  end
  
  it 'loglevel DEBUG should show debug messages' do
    @out = capture_stdout { 
      command_line('--log', 'stdout:debug')
    }
    @out.should include ' DEBUG '
  end
  
  it 'loglevel INFO should not show debug messages' do
    @out = capture_stdout { 
      command_line('--log', 'stdout:info')
    }
    @out.should_not include ' DEBUG '
  end
  
  it 'logging to file should work' do
    Rake.rm_rf "testdata/rrake.log", :verbose=>false
    @out = capture_stdout { 
      command_line('--log', 'testdata/rrake.log:info')
    }
    @out.should_not include ' DEBUG '
    @app.info 'logging2file'
    File.new('testdata/rrake.log', 'r').read.should include('logging2file')
  end
  
  if !Rake::Win32.windows?
  it 'logging to syslog should not raise error' do
    @out = capture_stdout { 
      command_line('--log', 'syslog:info')
    }
    @app.info 'logging2syslog'
    @out.should_not include ' DEBUG '
      # we can't read user.log as an ordinary user, so we can't test that it actually works.
  end
  end
  
  it "exit statement should give info log message" do
    @out = capture_stderr { 
      lambda {
        command_line('--log', 'stderr:info')
        @app.standard_exception_handling do
          exit
        end
      }.should raise_error SystemExit
    }
    @out.should match /INFO.*exit.*exit/
  end
  
  it "invalid command line argument should give fatal log message" do
    ARGV.clear
    ARGV << '--log'
    ARGV << 'stderr:fatal'
    ARGV << '--bad-argument'
    @app = Rake::Application.new
    @out = capture_stderr { 
      lambda {
        @app.init
      }.should raise_error SystemExit
    }
    @out.should match /FATAL .* --bad-argument/
  end
  
  it "Exception should give fatal and debug log message" do
    ARGV.clear
    ARGV << '--log'
    ARGV << 'stderr:debug'
    @app = Rake::Application.new
    @out = capture_stderr { 
      lambda {
       @app.init
        @app.standard_exception_handling do
          raise 'standard_exception_handling_caught_exception'
        end
      }.should raise_error SystemExit
    }
    @out.should match /FATAL .*standard_exception_handling_caught_exception/
    @out.should match /DEBUG .*stack trace/
  end
  
end
