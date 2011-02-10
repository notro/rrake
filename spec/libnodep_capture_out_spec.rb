

describe ::Rake::CaptureIO do
  it "should capture putc" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.putc "A"
    a.should == ["A"]
    o.rewind
    o.read.should == "A"
  end
  
  it "should capture puts" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.puts "A"
    a.should == ["A", "\n"]
    o.rewind
    o.read.should == "A\n"
  end
  
  it "should capture print" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.print "A"
    a.should == ["A"]
    o.rewind
    o.read.should == "A"
  end
  
  it "should capture printf" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.printf "%s", "A"
    a.should == ["A"]
    o.rewind
    o.read.should == "A"
  end
  
  it "should capture write" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.write "A"
    a.should == ["A"]
    o.rewind
    o.read.should == "A"
  end
  
  it "should capture syswrite" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.syswrite "A"
    a.should == ["A"]
    o.rewind
    o.read.should == "A"
  end
  
  it "should capture combination" do
    a = []
    o = ::Rake::CaptureIO.new { |s| a << s}
    o.write "Hello"
    o.putc " "
    o.print "old "
    o.puts "chap!"
    a.should == ["Hello", " ", "old ", "chap!", "\n"]
    o.rewind
    o.read.should == "Hello old chap!\n"
  end
  
end


describe ::Rake::CaptureOutput do
  it "should capture stdout" do
    o = ::Rake::CaptureOutput.new { print "Hello"; puts " World"}
    o.raw.should == [["stdout", "Hello"], ["stdout", " World"], ["stdout", "\n"]]
    o.output.should == [["stdout", "Hello World\n"]]
    o.to_s.should == "Hello World\n"
  end
  
  it "should capture stderr" do
    o = ::Rake::CaptureOutput.new { $stderr.print "Hello"; $stderr.puts " World"}
    o.raw.should == [["stderr", "Hello"], ["stderr", " World"], ["stderr", "\n"]]
    o.output.should == [["stderr", "Hello World\n"]]
    o.to_s.should == "Hello World\n"
  end
  
  it "should capture stdout and stderr" do
    o = ::Rake::CaptureOutput.new { $stderr.print "He"; $stderr.print "l"; $stderr.print "lo"; puts " World"; 
                                     $stderr.print "Good"; puts " Bye" }
    o.raw.should == [["stderr", "He"], ["stderr", "l"], ["stderr", "lo"], ["stdout", " World"], ["stdout", "\n"], 
                     ["stderr", "Good"], ["stdout", " Bye"], ["stdout", "\n"]]
    o.output.should == [["stderr", "Hello"], ["stdout", " World\n"], ["stderr", "Good"], ["stdout", " Bye\n"]]
    o.to_s.should == "Hello World\nGood Bye\n"
  end
  
end
