

describe "Rake::Task override_needed" do
  before :each do
    ::Rake.application.clear
  end
  
  it "should not execute if false is returned" do
    t = task :one do
      raise "should not get here"
    end
    test_marker = false
    t.override_needed { test_marker=true; false }
    t.invoke
    test_marker.should == true
  end
  
  it "should execute if true is returned" do
    t = task :one do
      nil
    end
    test_marker = false
    t.override_needed { test_marker=true; true }
    t.invoke
    test_marker.should == true
  end

  it "should receive the task object" do
    t = task :one do
      nil
    end
    test_marker = nil
    t.override_needed { |task| test_marker=task; false }
    t.invoke
    test_marker.should == t
  end
  
  it "should show up in investigation" do
    t = task :one
    t.investigation.should =~/needed.*true.*\(not overrided/
    t.override_needed do false end
    t.investigation.should =~/needed.*false.*\(overrided.*do\s*false\s*end/
    t.override_needed do var = "012345678901234567890123456789"; false end
    t.investigation.should =~/needed.*false.*\(overrided.*do\s*var.*\.\.\./
  end
end


describe "Rake::Task.strip_conditions" do
  before(:each) do
    ::Rake::Task.clear
  end

  it "empty args" do
    ::Rake::Task.strip_conditions([]).should == [[], {}]
  end
  
  it ":task" do
    ::Rake::Task.strip_conditions(:task).should == [[:task], {}]
  end
  
  it ":task => :task_1" do
    ::Rake::Task.strip_conditions(:task => :task_1).should == [[:task => :task_1], {}]
  end
  
  it ":task => [:task_1, :task_2]" do
    ::Rake::Task.strip_conditions(:task => [:task_1, :task_2]).should == [[:task => [:task_1, :task_2]], {}]
  end
  
  it ":task => [:task_1 => true]" do
    ::Rake::Task.strip_conditions(:task => [:task_1 => true]).should == [[:task => [:task_1]], {:task_1 => true}]
  end
  
  it ":task => [:task_1 => true, :task_2 => false]" do
    args, deps = Rake::Task.strip_conditions(:task => [:task_1 => true, :task_2 => false])
    args.first.keys.first.should == :task
    # For some reason :task_1 and :task_2 switches place in the array from time to time when some code changes in the test are made
    (args.first.values.first.sort_by {|sym| sym.to_s}).should == [:task_1, :task_2]
    deps.should == {:task_1 => true, :task_2 => false}
  end
end


describe Rake::Task do

  before(:all) do
    ::Rake.mkdir_p "testdata", :verbose=>false
    @file1 = "testdata/file1"
    @file2 = "testdata/file2"
    ::Rake.touch @file1
  end

  before(:each) do
    ::Rake::Task.clear
  end

  after(:all) do
    ::Rake.rm_f "testdata", :verbose=>false
  end

  it "should run without conditions and prerequisites" do
    t = task :task
    t.invoke
    t.needed?.should == true
  end

  it "should run without conditions but with prerequisite which runs" do
    t = task :task
    task :task_1
    task :task => :task_1
    t.invoke
    t.needed?.should == true
  end

  it "should fail on invoke if condition is missing in prerequisites" do
    t = task :task => [:task_1 => true]
    lambda {t.invoke}.should raise_error 
  end

  it "should run with condition as symbol expecting executing prerequisite" do
    task :task_1
    t = task :task => [:task_1 => true]
    t.invoke
    t.needed?.should == true
  end

  it "should run with condition as string expecting executing prerequisite" do
    task "task_1"
    t = task "task" => ["task_1" => true]
    t.invoke
    t.needed?.should == true
  end

  it "should be able to add conditions" do
    task :task_1
    t = task :task => [:task_1 => true]
	  file @file1
	  task :task => [@file1=>false]
    t.invoke
    t.needed?.should == true
  end

  it "should overwrite conditions with new condition for already conditioned prerequisite" do
    task :task_1
    task :task_2
    t = task :task => [:task_1 => true, :task_2 => false]
    task :task => [:task_2 => true]
    t.invoke
    t.needed?.should == true
  end

  it "should be able to clear conditions" do
    task :task_1
    t = task :task => [:task_1 => false]
	  t.clear_conditions
    t.invoke
    t.needed?.should == true
  end

  it "should run with many conditions and prerequisites" do
    t = task :task => [:task_1 => true, :task_2 => true, @file1 => false]
    task :task => [:task_3, @file2] # Do not care if they execute or not
    task :task_1
    task :task_2
    (task :task_3).override_needed {false}
    file @file1
    file @file2
    t.invoke
    t.needed?.should == true
  end

  it "should not run with many conditions and prerequisites" do
    t = task :task => [:task_1 => true, :task_2 => true, :task_3 => false, @file2 => false]
    task :task => [@file1]
    task :task_1
    task :task_2
    task :task_3
    file @file1
    file @file2
    t.invoke
    t.needed?.should == false
  end

  it "should work within namespace" do
    namespace :ns do
      task :task_1
      task :task_1_1
      file @file1
      task :task_1 => [:task_1_1 => true, @file1 => false]
    end
    t = task :task => ["ns:task_1" => true]
    t.invoke
    t.needed?.should == true
  end
  
  it "conditions should show up in investigation" do
    t = task :one
    t.investigation.should =~/conditions.*\{\}$/
    task :one => [:two => false, :three => true]
    task :two
    task :three
    t.investigation.should =~/conditions.*\{.*two.*false.*\}$/
    t.investigation.should =~/conditions.*\{.*three.*true.*\}$/
  end
end


describe "Rake::Task.remote" do

  before(:all) do
    ::Rake.application.clear
  end
  
  [["server.com", "http://server.com:#{::Rake.application.options.port}"],
   ["server.com:4567", "http://server.com:4567"],
   ["server.com/path", "http://server.com:#{::Rake.application.options.port}/path"],
   ["server.com:4567/path", "http://server.com:4567/path"],

   ["192.168.1.1", "http://192.168.1.1:#{::Rake.application.options.port}"],
   ["192.168.1.1:4567", "http://192.168.1.1:4567"],
   ["192.168.1.1/path", "http://192.168.1.1:#{::Rake.application.options.port}/path"],
   ["192.168.1.1:4567/path", "http://192.168.1.1:4567/path"],

   ["http://server.com", "http://server.com:#{::Rake.application.options.port}"],
   ["http://server.com:4567", "http://server.com:4567"],
   ["http://server.com/path", "http://server.com:#{::Rake.application.options.port}/path"],
   ["http://server.com:4567/path", "http://server.com:4567/path"],

   ["http://192.168.1.1", "http://192.168.1.1:#{::Rake.application.options.port}"],
   ["http://192.168.1.1:4567", "http://192.168.1.1:4567"],
   ["http://192.168.1.1/path", "http://192.168.1.1:#{::Rake.application.options.port}/path"],
   ["http://192.168.1.1:4567/path", "http://192.168.1.1:4567/path"],
  ].each do |test|

    it "should accept #{test[0]}" do
      t = task :one
      t.remote = test[0]
      t.remote.should == test[1]
    end

  end
  
  ["", "456", "192.168.1", "192.168.1:45", "http://192.168.1"].each do |test|

    it "should fail with #{test}" do
      t = task :one
      lambda { t.remote = test }.should raise_error ArgumentError
    end

  end
  
end


describe "remote keyword" do

  before(:all) do
    ::Rake.application.clear
  end
  
  it "should set Task.remote" do
    remote "server.com"
    t = task :one
    t.remote.should == "http://server.com:#{::Rake.application.options.port}"
  end
  
  it "after initial remote with host, subsequent remotes should set Task.remote to the initial value" do
    remote "server.com"
    t1 = task :one
    remote
    t2 = task :two
    remote
    t3 = task :three
    t2.remote.should == "http://server.com:#{::Rake.application.options.port}"
    t3.remote.should == "http://server.com:#{::Rake.application.options.port}"
  end
  
  it "multiple remote on the same task should change the value" do
    remote "server.com"
    t = task :one
    t.remote.should == "http://server.com:#{::Rake.application.options.port}"
    remote "server.org"
    t = task :one
    t.remote.should == "http://server.org:#{::Rake.application.options.port}"
  end
end
