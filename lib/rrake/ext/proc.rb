######################################################################
# Rake extension methods for Proc.
#

require 'proc_source'

# Doesn't handled eval'd procs
#   For solution to this see eval redef: http://bjax.rubyforge.org/svn/trunk/bjax/lib/serialize_proc.rb
# We don't use ruby2ruby because of windows.
#   The ruby2ruby gem needs to compile some code, which is a hassle on Windows.
class Proc # :nodoc:
  rake_extension("_dump") do
    # Dump to Marshal format.
    def _dump(limit)
      fail "can't dump eval'd proc" if source.nil?
#      puts "_dump(#{limit})\n  fn: #{source.file}\n  line: #{source.lines.first}"
      str = Marshal.dump([source.to_s, source.file, source.lines.first])
#      print "  => "; p str
      str
    end
  end
  
  rake_extension("_load") do
    # Load from Marshal format. Uses eval.
    def self._load(str)
#      print "self._load "; p str
      proc_str, fn, line = Marshal.load(str)
#      print "  proc_str: "; p proc_str
#      puts "  fn: #{fn}\n  line: #{line}"
      eval("Proc.new #{proc_str}", binding, fn, line.to_i)
    end
  end
end





=begin
require 'ruby2ruby'
require 'sexp_processor'
require 'unified_ruby'
require 'parse_tree'


# Monkey-patch to have Ruby2Ruby#translate with r2r >= 1.2.3. 
# Ref: https://gist.github.com/321038
class Ruby2Ruby < SexpProcessor
  def self.translate(klass_or_str, method = nil)
    #print "translate: "; p klass_or_str
    sexp = ParseTree.translate(klass_or_str, method)
    unifier = Unifier.new
    unifier.processors.each do |p|
      p.unsupported.delete :cfunc # HACK
    end
    sexp = unifier.process(sexp)
    self.new.process(sexp)
  end
end


class Proc
  rake_extension("to_ruby") do
  # Turn proc into ruby code. Returns a string.
    def to_ruby
      # http://www.rubyquiz.com/quiz38.html
      # regex: http://www.ruby-forum.com/topic/163217
      #print "to_ruby: #{self.class} "; p self
      block = self.dup
      c = Class.new 
      c.class_eval do 
        define_method :dump, &block
      end 
      str = Ruby2Ruby.translate(c, :dump)
      #print "  str: "; p str
      #puts "  arity: #{arity}"
      case arity
      when -1
        # On Ruby 1.8.7 both {} and {|*a|} gives arity of -1. The first should be 0.
        if str.index("def dump(") == 0
          str.gsub!("def dump(", "")
          i = str.index(")")
          body = str[i+1..-1]
          args = "|" + str[0..i-1] + "| "
        else
          body = str.gsub("def dump", "")
          args = ""
        end
      when 0
        body = str.gsub("def dump", "")
        args = "|| "
      else
        str.gsub!("def dump(", "")
        i = str.index(")")
        body = str[i+1..-1]
        args = "|" + str[0..i-1] + "| "
      end
      #print "  body: "; p body
      #print "  args: "; p args
      body = body[0..(body.rindex("end")-1)].strip
      #print "  body: "; p body
      str = "{ #{args}" + body + " }"
      #print "  str: "; p str
      str
    end
  end
  
  rake_extension("_dump") do
    # Dump to Marshal format.
    def _dump(limit)
      source = inspect.split("@")[1]
      i = source.rindex(':')
      fn = source[0..i-1]
      begin
        uri = DRb::uri
      rescue
        uri = nil
      end
      fn = uri + fn if (source.include?("://") == false and uri)
      line = source[i+1..-2]
      str = Marshal.dump([to_ruby,fn,line])
      #puts "_dump(#{limit})\n  fn: #{fn}\n  line: #{line}"
      #print "  => "; p str
      #print_call_stack
      str
    end
  end
  
  rake_extension("_load") do
    # Load from Marshal format. Uses eval.
    def self._load(str)
      #print "self._load "; p str
      proc_str, fn, line = Marshal.load(str)
      #print "  proc_str: "; p proc_str
      #puts "  fn: #{fn}\n  line: #{line}"
      eval("Proc.new #{proc_str}", binding, fn, line.to_i)
    end
  end
end
=end