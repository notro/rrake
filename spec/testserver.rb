require 'tmpdir'
require 'rrake'
require 'rrake/win32'

begin
  require 'win32/process' if Rake::Win32.windows?
rescue LoadError
  fail "win32-process gem is needed on Windows"
end


module TestServer
  @instance = nil
  
  extend self
  
  def instance
    @instance ||= RRakeServer.new
  end
  
  def start
    instance
    @fpos = logfile.tell
  end
  
  def shutdown
    @instance.shutdown if @instance
  end
  
  def logfile
    instance.logfile
  end
  
  def msg_all
    logfile.pos = @fpos
    logfile.read
  end
  
  def msg
    logfile.read
  end
  
  def pwd
    @instance.rget "pwd"
  end
  
  def chdir(dir, &block)
    olddir = pwd if block_given?
    @instance.rput "chdir", :dir => dir
    if block_given?
      begin
        yield
      ensure
        @instance.rput "chdir", :dir => olddir
      end
    end
  end
end


class RRakeServer
  include Rake::RestClient
  
  attr_reader :logfile, :pid, :url, :log_context

  def initialize
    logfile = 'testserver/server.log'
    FileUtils.mkdir_p File.dirname logfile
    FileUtils.rm_f logfile
    FileUtils.touch logfile

    @verbose = ENV['VERBOSE']
    env = ENV['DEBUG'] ? "development" : "test"
    cmd = "#{FileUtils::RUBY} -Ilib bin/rrake --log #{logfile}:all --server --host 127.0.0.1 -s webrick -E #{env}"
    puts "Starting server: #{cmd}\n\n" if @verbose
    @pipe = IO.popen(cmd)
    @logfile = File.open logfile
    timeout = 0
    msg = ''
    while msg !~ /pid/
      sleep 0.1
      msg = @logfile.read
      if msg =~/stack trace/
        @logfile.rewind
        $stderr.puts "\n\n#{@logfile.path}:"
        $stderr.puts @logfile.read
        fail "rrake aborted, could not start server #{msg =~ /bind/ ? '(port in use?)' : ''}"
      end
      timeout += 1
      fail "timeout, could not start server" if timeout > 300
    end
    @logfile.rewind
    msg = @logfile.read
    u = msg.scan(/TCPServer.*(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b),\s(\d+)/)
    @url = "http://#{u[0][0]}:#{u[0][1]}/api/v1"
    @log_context = "RRakeServer"
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
      timeout = 0
      until @logfile.read =~ /shutdown/
        sleep 0.1
        timeout += 1
        fail "timeout, could not shutdown server" if timeout > 300
      end
    end
  end
end
