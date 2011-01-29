
describe Proc do
  it "source should convert a simple proc to ruby code" do
    p = Proc.new {
      false
    }
    p.source.split.join(' ').should == "{ false }"
  end
  
  it "source should convert a more complicated proc to ruby code" do
    p = Proc.new do
      print 'hello'
      (1..10).each { |i|
        print i
      }
    end
    p.source.split.join(' ').should == "do print 'hello' (1..10).each { |i| print i } end"
  end
  
  it "Marshal should work with simple proc" do
    p = Proc.new do
      false
    end
    pm = Marshal.load(Marshal.dump(p))
    pm.source.should == p.source
    p.call.should == false
    pm.call.should == false
  end
  
  it "Marshal should work with more complex proc" do
    p = Proc.new do |a,b,c,d|
      sum = 0
      (1..10).each do |i|
        sum += a*i + b*i + c*i + d*i
      end
      sum
    end
    pm = Marshal.load(Marshal.dump(p))
    pm.source.should == p.source
    p.call(2,3,5,7).should == 935
    pm.call(2,3,5,7).should == 935
  end
  
  it "Marshal should handle procs with argument: <none>" do
    p = Proc.new { true }
#    print "p = (#{p.arity}) "; p p.source
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: ||" do
    p = Proc.new { || true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: |a|" do
    p = Proc.new { |a| true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: |a,b|" do
    p = Proc.new { |a,b| true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: |a,b,c|" do
    p = Proc.new { |a,b,c| true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: |*a|" do
    p = Proc.new { |*a| true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
  it "Marshal should handle procs with argument: |a,*b|" do
    p = Proc.new { |a,*b| true }
    Marshal.load(Marshal.dump(p)).arity.should == p.arity
  end
    
end




=begin
describe Proc do
  it "to_ruby should convert a simple proc to ruby code" do
    p = Proc.new do
      false
    end
    p.to_ruby.split.join(' ').should == "{ false }"
  end
  
  it "to_ruby should convert a more complicated proc to ruby code" do
    p = Proc.new do
      print 'hello'
      (1..10).each do |i|
        print i
      end
    end
    p.to_ruby.split.join(' ').should == "{ print(\"hello\") (1..10).each { |i| print(i) } }"
  end
  
  it "Marshal should work with simple proc" do
    p = Proc.new do
      false
    end
    pm = Marshal.load(Marshal.dump(p))
    pm.to_ruby.should == p.to_ruby
    p.call.should == false
    pm.call.should == false
  end
  
  it "Marshal should work with more complex proc" do
    p = Proc.new do |a,b,c,d|
      sum = 0
      (1..10).each do |i|
        sum += a*i + b*i + c*i + d*i
      end
      sum
    end
    pm = Marshal.load(Marshal.dump(p))
    pm.to_ruby.should == p.to_ruby
    p.call(2,3,5,7).should == 935
    pm.call(2,3,5,7).should == 935
  end
  
  ["", "||", "|a|", "|a,b|", "|a,b,c|", "|*a|", "|a,*b|"].each do |args|
    it "to_ruby should handle procs with argument: \"#{args}\"" do
      p = eval("Proc.new { #{args} true }")
      Marshal.load(Marshal.dump(p)).arity.should == p.arity
    end
  end
  
end
=end