# test/lib/multitask_test.rb


describe "TestMultiTask" do
  before :all do
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    if false
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all if ENV['DEBUG']
      puts "--------------------------------------------------------------------"
    end
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_running_multitasks" do
    remote "127.0.0.1"
    task :a do |t| 3.times do |i| t.fatal "A#{i}"; sleep 0.01; end end
    remote
    task :b do |t| 3.times do |i| t.fatal "B#{i}"; sleep 0.01;  end end
    remote
    multitask :both => [:a, :b]
    ::Rake::Task[:both].invoke
    msg = TestServer.msg
    runs = msg.lines.select { |l| l.include? "FATAL"}
    runs.size.should == 6
    (runs.index { |r| r.include?("A0") }).should < (runs.index { |r| r.include?("A1") })
    (runs.index { |r| r.include?("A1") }).should < (runs.index { |r| r.include?("A2") })
    (runs.index { |r| r.include?("B0") }).should < (runs.index { |r| r.include?("B1") })
    (runs.index { |r| r.include?("B1") }).should < (runs.index { |r| r.include?("B2") })
  end

  it "test_all_multitasks_wait_on_slow_prerequisites" do
    remote "127.0.0.1"
    task :slow do |t| 3.times do |i| t.fatal "S#{i}"; sleep 0.05 end end
    remote
    task :a => [:slow] do |t| 3.times do |i| t.fatal "A#{i}"; sleep 0.01 end end
    remote
    task :b => [:slow] do |t| 3.times do |i| t.fatal "B#{i}"; sleep 0.01 end end
    remote
    multitask :both => [:a, :b]
    ::Rake::Task[:both].invoke
    msg = TestServer.msg
    runs = msg.lines.select { |l| l.include? "FATAL"}
    runs.size.should == 9
    (runs.index { |r| r.include?("S0") }).should < (runs.index { |r| r.include?("S1") })
    (runs.index { |r| r.include?("S1") }).should < (runs.index { |r| r.include?("S2") })
    (runs.index { |r| r.include?("S2") }).should < (runs.index { |r| r.include?("A0") })
    (runs.index { |r| r.include?("S2") }).should < (runs.index { |r| r.include?("B0") })
    (runs.index { |r| r.include?("A0") }).should < (runs.index { |r| r.include?("A1") })
    (runs.index { |r| r.include?("A1") }).should < (runs.index { |r| r.include?("A2") })
    (runs.index { |r| r.include?("B0") }).should < (runs.index { |r| r.include?("B1") })
    (runs.index { |r| r.include?("B1") }).should < (runs.index { |r| r.include?("B2") })
  end
end
