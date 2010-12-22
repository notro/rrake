
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
