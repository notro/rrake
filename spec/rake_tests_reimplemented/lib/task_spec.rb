# test/lib/task_test.rb


describe "TestTask" do
  include CaptureStdout
  
  before :all do
    ::Rake::TaskManager.record_task_metadata = true
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    rm_f "testdata"
    ::Rake::TaskManager.record_task_metadata = false
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_create" do
    arg = nil
    remote "127.0.0.1"
    t = task(:name) do |task| task.fatal task.name end
    t.name.should == "name"
    t.prerequisites.should == []
    t.needed?.should == true
    t.execute(0)
    TestServer.msg.should =~ /FATAL.*name/
    t.source.should == nil
    t.sources.should == []
    t.locations.size.should == 1
    t.locations.first.should =~/#{Regexp.quote(__FILE__)}/
  end

  it "test_invoke" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2, :t3]) do |t| t.fatal t.name; 3321 end
    remote
    t2 = task(:t2) do |t| t.fatal t.name end
    remote
    t3 = task(:t3) do |t| t.fatal t.name end
    t1.prerequisites.should == ["t2", "t3"]
    t1.invoke
    TestServer.msg.should =~ /FATAL.*t2.*FATAL.*t3.*FATAL.*t1/m
  end

  it "test_invoke_with_circular_dependencies" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2]) do |t| t.fatal t.name; 3321 end
    remote
    t2 = task(:t2 => [:t1]) do |t| t.fatal t.name end
    t1.prerequisites.should == ["t2"]
    t2.prerequisites.should == ["t1"]
    expect{ t1.invoke }.to raise_error RuntimeError, /circular dependency.*t1 => t2 => t1/i
  end

  it "test_no_double_invoke" do
    remote "127.0.0.1"
    t1 = task(:t1 => [:t2, :t3]) do |t| t.fatal t.name; 3321 end
    remote
    t2 = task(:t2 => [:t3]) do |t| t.fatal t.name end
    remote
    t3 = task(:t3) do |t| t.fatal t.name end
    t1.invoke
    TestServer.msg.should =~ /FATAL.*t3.*FATAL.*t2.*FATAL.*t1/m
  end

  it "test_can_double_invoke_with_reenable" do
    remote "127.0.0.1"
    t1 = task(:t1) do |t| t.fatal t.name end
    t1.invoke
    t1.reenable
    t1.invoke
    TestServer.msg.should =~ /FATAL.*t1.*FATAL.*t1/m
  end

  it "test_multi_invocations" do
    p = proc do |t| t.fatal t.name end
    remote "127.0.0.1"
    task({:t1=>[:t2,:t3]}, &p)
    remote
    task({:t2=>[:t3]}, &p)
    remote
    task(:t3, &p)
    ::Rake::Task[:t1].invoke
    TestServer.msg.should =~ /FATAL.*t3.*FATAL.*t2.*FATAL.*t1/m
  end

  it "test_timestamp_returns_now_if_all_prereqs_have_no_times" do
    remote "127.0.0.1"
    a = task :a => ["b", "c"]
    remote
    b = task :b
    remote
    c = task :c

    # This can't be tested like the original test, because Time.now is accessed in another process.
    time = Time.now
    a.timestamp.should be_within(1).of(time)
  end
end  


describe "TestTaskWithArguments" do
  include CaptureStdout
  
  before :all do
    ::Rake::TaskManager.record_task_metadata = true
    TestServer.start
  end
  
  after :all do
    ::Rake.application.clear
    rm_f "testdata"
    ::Rake::TaskManager.record_task_metadata = false
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  it "test_arg_list_is_empty_if_no_args_given" do
    remote "127.0.0.1"
    t = task(:t) do |tt, args|
      tt.fatal "args is empty" if args.to_hash.empty?
    end
    t.invoke(1, 2, 3)
    TestServer.msg.should =~ /FATAL.*args is empty/
  end

  it "test_tasks_can_access_arguments_as_hash" do
    remote "127.0.0.1"
    t = task :t, :a, :b, :c do |tt, args|
      # Proc#source can't handle {:a=>1}
      hash = Hash.new
      hash[:a] = 1
      hash[:b] = 2
      hash[:c] = 3
      if args.to_hash == hash then
        tt.fatal "to_hash" 
      end
      tt.fatal "argsa" if args[:a] == 1
      tt.fatal "argsb" if args[:b] == 2
      tt.fatal "argsc" if args[:c] == 3
      tt.fatal "args_a" if args.a == 1
      tt.fatal "args_b" if args.b == 2
      tt.fatal "args_c" if args.c == 3
    end
    t.invoke(1, 2, 3)
    TestServer.msg.should =~ /FATAL.*to_hash.*FATAL.*argsa.*FATAL.*argsb.*FATAL.*argsc.*FATAL.*args_a.*FATAL.*args_b.*FATAL.*args_c/m
  end

  it "test_actions_of_various_arity_are_ok_with_args" do
    remote "127.0.0.1"
    t = task(:t, :x) do
      puts "a"
    end
    t.enhance do | |
      puts "b"
    end
    t.enhance do |task|
      puts "c"
      task.fatal "c"
      puts "Task" if task.kind_of? Rake::Task
      task.fatal "Task" if task.kind_of? Rake::Task
    end
    t.enhance do |t2, args|
      t2.fatal "d"
      t2.fatal "-#{t2.name}-"
      hash = Hash.new
      hash[:x] = 1
      t2.fatal "to_hash" if args.to_hash == hash
    end
    out = capture_stdout { 
      t.invoke(1)
    }
    out.should =~ /a\nb\nc\nTask\n/
    TestServer.msg.should =~ /FATAL.*c.*FATAL.*Task.*FATAL.*d.*FATAL.*-t-.*FATAL.*to_hash/m
  end
  
  it "test_arguments_are_passed_to_block" do
    remote "127.0.0.1"
    t = task(:t, :a, :b) do |tt, args|
      hash = Hash.new
      hash[:a] = 1
      hash[:b] = 2
      tt.fatal "to_hash" if args.to_hash == hash
    end
    t.invoke(1,2)
    TestServer.msg.should =~ /FATAL.*to_hash/
  end

  it "test_extra_parameters_are_ignored" do
    remote "127.0.0.1"
    t = task(:t, :a) do |tt, args|
      tt.fatal "args_a" if args.a == 1
      tt.fatal "args_b" if args.b.nil?
    end
    t.invoke(1,2)
    TestServer.msg.should =~ /FATAL.*args_a.*FATAL.*args_b/m
  end

  it "test_arguments_are_passed_to_all_blocks" do
    remote "127.0.0.1"
    t = task :t, :a
    remote
    task :t do |tt, args|
      tt.fatal "argsa" if args[:a] == 1
    end
    remote
    task :t do |tt, args|
      tt.fatal "argsa" if args[:a] == 1
    end
    t.invoke(1)
    TestServer.msg.should =~ /FATAL.*argsa.*FATAL.*argsa/m
  end

  it "test_block_with_no_parameters_is_ok" do
    remote "127.0.0.1"
    t = task(:t) do end
    t.invoke(1, 2)
  end

  it "test_named_args_are_passed_to_prereqs" do
    remote "127.0.0.1"
    pre = task(:pre, :rev) do |t, args| t.fatal args.rev end
    remote
    t = task(:t, :name, :rev, :needs => [:pre])
    t.invoke("bill", "1.2")
    TestServer.msg.should =~ /FATAL.*1.2/
  end

  it "test_args_not_passed_if_no_prereq_names" do
    remote "127.0.0.1"
    pre = task(:pre) do |t, args|
      t.fatal "args is empty" if args.to_hash.empty?
      t.fatal args.name.inspect
    end
    remote
    t = task(:t, :name, :rev, :needs => [:pre])
    t.invoke("bill", "1.2")
    TestServer.msg.should =~ /FATAL.*args is empty.*FATAL.*nil/m
  end

  it "test_args_not_passed_if_no_arg_names" do
    remote "127.0.0.1"
    pre = task(:pre, :rev) do |t, args|
      t.fatal "args is empty" if args.to_hash.empty?
    end
    remote
    t = task(:t, :needs => [:pre])
    t.invoke("bill", "1.2")
    TestServer.msg.should =~ /FATAL.*args is empty/
  end
end
