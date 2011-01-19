require 'tmpdir'
require 'rrake'
require 'rrake/win32'

begin
  require 'win32/process' if Rake::Win32.windows?
rescue LoadError
  fail "win32-process gem is needed on Windows"
end

require 'test/capture_stdout'
require 'test/in_environment'


module CommandHelp
  def command_line(*options)
    options.each do |opt| ARGV << opt end
    @app = Rake::Application.new
    def @app.exit(*args)
      throw :system_exit, :exit
    end
    @app.instance_eval do
      handle_options
      collect_tasks
    end
    @tasks = @app.top_level_tasks
    @app.options
  end
end


class TestRakeServer
  attr_reader :logfile, :pid

  def initialize
    mkdir_p 'testdata'
    rm_f 'testdata/server.log'
    touch 'testdata/server.log'

    @verbose = ! ENV['VERBOSE'].nil?
    env = @verbose ? "development" : "test"
    cmd = "#{RUBY} -Ilib bin/rrake --log testdata/server.log:all --server --host 127.0.0.1 -s webrick -E #{env}"
    puts "Starting server: #{cmd}\n\n" if @verbose
    @pipe = IO.popen(cmd)
    @logfile = File.open "testdata/server.log"
    timeout = 0
    msg = ''
    chars = %w{ | / - \\ }
    while msg !~ /pid/
      print chars[0]
      sleep 0.1
      print "\b"
      chars.push chars.shift
      msg = @logfile.read
      if msg =~/stack trace/
        @logfile.rewind
        $stderr.puts "\n\n#{@logfile.path}:"
        $stderr.puts @logfile.read
        fail "rrake aborted, could not start server #{msg =~ /bind/ ? '(port in use?)' : ''}"
      end
      timeout += 1
      fail "timeout, could not start server" if timeout > 600
    end
    @logfile.rewind
  end

  def pid
    @pipe.pid
  end

  def shutdown
    if Rake::Win32.windows?
      # win32/process, Process.kill:
      #   'INT' works only if the process was created with the CREATE_NEW_PROCESS_GROUP flag.
      fail "could not shutdown server" if Process.kill('KILL', pid) == []
    else
      Process.kill 'INT', pid
      sleep 0.1
      fail "could not shutdown server" unless @logfile.read =~ /shutdown/
    end
  end
end


Rake.application.init
