
module Rake
  # CaptureIO is based on StringIO and yields everything written to it.
  #   out_array = []
  #   out = CaptureIO.new { |s| out_array << s }
  #   out.print "Hello "
  #   out.puts "World"
  #   out_array == ["Hello ", "World\n"]
  class CaptureIO < StringIO
    def initialize(*a, &block)
      @block = block if block_given?
      super
    end
    def putc(string)
      @block.call string if @block
      super
    end
    def write(string)
      @block.call string if @block
      super
    end
    def syswrite(string)
      @block.call string if @block
      super
    end
  end
  
  
  # Captures everything written to stdout and stderr
  class CaptureOutput
    def initialize
      @out = []
      stdout = CaptureIO.new { |s| @out << ["stdout", s] }
      stderr = CaptureIO.new { |s| @out << ["stderr", s] }
      oldstdout = $stdout
      oldstderr = $stderr
      $stdout = stdout
      $stderr = stderr
      yield
    ensure
      $stdout = oldstdout
      $stderr = oldstderr
    end
    
    def raw # :nodoc:
      @out
    end
    
    # Return the captured output as an array
    #   => [[:stdout, "Hello"], [:stderr, "World"]]
    def output
      compact = []
      last = nil
      @out.each { |std, s|
        if std == last
          l = compact.pop
          compact << [std, l[1] + s]
        else
          compact << [std, s]
          last = std
        end
      }
      compact
    end
    
    def to_s
      str = ""
      @out.each { |std, s| str += s }
      str
    end
    
  end
end