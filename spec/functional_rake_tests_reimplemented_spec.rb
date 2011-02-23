require "#{File.dirname(File.dirname(__FILE__))}/test/filecreation"


describe "standard rake test cases" do
  include CaptureStdout

  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    ::Rake::TaskManager.record_task_metadata = true
    TestServer.start
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
  end
  
  after :all do
    ::Rake.application.clear
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all
      puts "--------------------------------------------------------------------"
    end
    rm_f "testdata"
    ::Rake::TaskManager.record_task_metadata = false
  end
  
  # test/lib/application_test.rb
  describe "TestApplication" do
    include InEnvironment
    
    before :all do
      @app = ::Rake::Application.new
      @app.options.rakelib = []
    end
    
    before :each do
      @app.clear
      TestServer.msg
    end
    
    xit "test_building_imported_files_on_demand" do
      mock = flexmock("loader")
      mock.should_receive(:load).with("x.dummy").once
      mock.should_receive(:make_dummy).with_no_args.once
      @app.instance_eval do
        intern(Rake::Task, "x.dummy").enhance do mock.make_dummy end
          add_loader("dummy", mock)
        add_import("x.dummy")
        load_imports
      end
    end
    
    xit "test_good_run" do
      ARGV.clear
      ARGV << '--rakelib=""'
      ARGV << '--log'
      ARGV << 'stderr:debug2'
      @app.options.silent = true
      @app.last_remote = "127.0.0.1"
      @app.instance_eval do
        intern(::Rake::Task, "default").enhance do |t| puts "-test_good_run-" end
      end
      in_environment("PWD" => "test/data/default") do
        @out = capture_stdout {  @app.run }
      end
      @out.should == "-test_good_run-\n"
    end
  end
  
  # test/lib/task_test.rb
  describe "TestTask" do
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
  
  # test/lib/task_test.rb
  describe "TestTaskWithArguments" do
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
  
  # test/lib/definitions_test.rb
  describe "TestDefinitions" do
  
    EXISTINGFILE = "testdata/existing"
    
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    it "test_task" do
      remote "127.0.0.1"
      task :one => [:two] do |t| t.fatal "done" end
      remote
      task :two
      remote
      task :three => [:one, :two]
      check_tasks(:one, :two, :three)
      TestServer.msg.should =~ /FATAL.*done/
    end

    it "test_file_task" do
      remote "127.0.0.1"
      file "testdata/one" => "testdata/two" do |t| t.fatal "done" end
      remote
      file "testdata/two"
      remote
      file "testdata/three" => ["testdata/one", "testdata/two"]
      check_tasks("testdata/one", "testdata/two", "testdata/three")
      TestServer.msg.should =~ /FATAL.*done/
    end

    it "test_incremental_definitions" do
      remote "127.0.0.1"
      task :t1 => [:t2] do puts "A"; 4321 end
      task :t1 => [:t3] do puts "B"; 1234 end
      task :t1 => [:t3]
      remote
      task :t2
      remote
      task :t3
      out = capture_stdout { 
        ::Rake::Task[:t1].invoke
      }
      out.should == "A\nB\n"
      ::Rake::Task[:t1].prerequisites.should == ["t2", "t3"]
    end

    it "test_implicit_file_dependencies" do
      create_existing_file
      remote "127.0.0.1"
      task :y => [EXISTINGFILE] do |t| t.fatal t.name end
      ::Rake::Task[:y].invoke
      TestServer.msg.should =~ /FATAL.*y/
    end
    
    def check_tasks(n1, n2, n3)
      t = ::Rake::Task[n1]
      t.should be_kind_of ::Rake::Task
      t.name.should == n1.to_s
      (t.prerequisites.collect{|n| n.to_s}).should == [n2.to_s]
      t.invoke
      t2 = ::Rake::Task[n2]
      t2.prerequisites.should == ::Rake::FileList[]
      t3 = ::Rake::Task[n3]
      (t3.prerequisites.collect{|n|n.to_s}).should == [n1.to_s, n2.to_s]
    end
    
    def create_existing_file
      Dir.mkdir File.dirname(EXISTINGFILE) unless
        File.exist?(File.dirname(EXISTINGFILE))
      open(EXISTINGFILE, "w") do |f| f.puts "HI" end unless
        File.exist?(EXISTINGFILE)
    end
  end
  
  # test/lib/file_task_test.rb
  describe "TestFileTask" do
    include FileCreation
    
    before :all do
      ::Rake::Task.clear
#      FileUtils.rm_f ::FileCreation::NEWFILE
#      FileUtils.rm_f ::FileCreation::OLDFILE
      ::Rake.rm_rf "testdata", :verbose=>false
    end
    
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    xit "test_file_times_old_depends_on_new" do
      create_timed_files(::FileCreation::OLDFILE, ::FileCreation::NEWFILE)

      remote "127.0.0.1"
      t1 = ::Rake.application.intern(::Rake::FileTask,::FileCreation::OLDFILE).enhance([::FileCreation::NEWFILE])
      remote
      t2 = ::Rake.application.intern(::Rake::FileTask, ::FileCreation::NEWFILE)
      t2.needed?.should == false
      preq_stamp = t1.prerequisites.collect{|t| ::Rake::Task[t].timestamp}.max
      t2.timestamp.should == preq_stamp
      t1.timestamp.should < preq_stamp
      t1.needed?.should == true
    end

    it "test_file_depends_on_task_depend_on_file" do
      create_timed_files(::FileCreation::OLDFILE, ::FileCreation::NEWFILE)

      remote "127.0.0.1"
      file ::FileCreation::NEWFILE => [:obj] do |t| t.fatal t.name end
      remote
      task :obj => [::FileCreation::OLDFILE] do |t| t.fatal t.name end
      remote
      file ::FileCreation::OLDFILE           do |t| t.fatal t.name end

      ::Rake::Task[:obj].invoke
      ::Rake::Task[::FileCreation::NEWFILE].invoke
      TestServer.msg.should_not =~ /FATAL.*#{::FileCreation::NEWFILE}/
    end
  end
  
  describe "TestDirectoryTask" do
    before :all do
      ::Rake.rm_rf "testdata", :verbose=>false
    end
    
    after :all do
      ::Rake.rm_rf "testdata", :verbose=>false
    end
    
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    if ::Rake::Win32.windows?
      xit "test_directory_win32" do
        desc "WIN32 DESC"
        FileUtils.mkdir_p("testdata")
        Dir.chdir("testdata") do
          remote "127.0.0.1"
          directory 'c:/testdata/a/b/c'
::Rake.application.tasks.each { |name|
  puts ::Rake::Task[name].investigation
}
         ::Rake::Task['c:/testdata'].class.should == ::Rake::FileCreationTask
          ::Rake::Task['c:/testdata/a'].class.should == ::Rake::FileCreationTask
          ::Rake::Task['c:/testdata/a/b/c'].class.should == ::Rake::FileCreationTask
          ::Rake::Task['c:/testdata'].comment.should == nil
          ::Rake::Task['c:/testdata/a/b/c'].comment.should == "WIN32 DESC"
          ::Rake::Task['c:/testdata/a/b'].comment.should == nil
          verbose(false) {
            ::Rake::Task['c:/testdata/a/b'].invoke
          }
          File.exist?('c:/testdata/a/b').should == true
          File.exist?('c:/testdata/a/b/c').should == false
        end
      end
    end
  end

  # test/lib/multitask_test.rb
  describe "TestMultiTask" do
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    def add_run(obj)
      @mutex.synchronize do
        @runs << obj
      end
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
  
  # test/lib/task_manager_test.rb
  describe "TestTaskManager" do
    before :each do
      ::Rake.application.clear
      #TestServer.msg
    end
    
    xit "test_correctly_scoped_prerequisites_are_invoked" do
      @tm = ::Rake::Application.new
      @tm.last_remote = "127.0.0.1"
      @tm.define_task(::Rake::Task, :z) #do puts "top z" end
puts "\n\nurl: #{@tm['z'].url}\n\n"
puts TestServer.msg
      @tm.in_namespace("a") do
        @tm.define_task(::Rake::Task, :z) do puts "next z" end
        @tm.define_task(::Rake::Task, :x => :z)
      end

      out = capture_stdout { 
      @tm["a:x"].invoke
      }
      out.should == "next z\n"
    end
  end
  
  # test/lib/rules_test.rb
  describe "TestRules" do
    include FileCreation
    
    SRCFILE  = "testdata/abc.c"
    SRCFILE2 =  "testdata/xyz.c"
    FTNFILE  = "testdata/abc.f"
    OBJFILE  = "testdata/abc.o"
    FOOFILE  = "testdata/foo"
    DOTFOOFILE = "testdata/.foo"

    before :all do
      ::Rake::Task.clear
#::Rake.application.options.trace_rules = true
    end

    after :all do
      FileList['testdata/*'].uniq.each do |f| rm_r(f, :verbose=>false) end
#puts      TestServer.msg
    end
    
    before :each do
      ::Rake.application.clear
      TestServer.msg
      @runs = nil
    end
    
    def runs
      return @runs unless @runs.nil?
      @runs = []
      @msg = TestServer.msg
      fatal = @msg.lines.select { |l| l.include? "FATAL"}
      fatal.each { |f| m = f.match(/--(.+)--/); @runs << m[1] if m }
      @runs
    end
    
    xit "test_multiple_rules1" do
      TestServer.msg
      create_file(FTNFILE)
      delete_file(SRCFILE)
      delete_file(OBJFILE)
      remote "127.0.0.1"
      rule(/\.o$/ => ['.c']) do |t| t.fatal "--C--" end
      remote
      rule(/\.o$/ => ['.f']) do |t| t.fatal "--F--" end
      remote
      t = ::Rake::Task[OBJFILE]
      t.invoke
      ::Rake::Task[OBJFILE].invoke
      runs.should == ["F"]
    end

    xit "test_multiple_rules2" do
      create_file(FTNFILE)
      delete_file(SRCFILE)
      delete_file(OBJFILE)
      remote "127.0.0.1"
      rule(/\.o$/ => ['.f']) do |t| t.fatal "--F--" end
      remote
      rule(/\.o$/ => ['.c']) do |t| t.fatal "--C--" end
      remote
      ::Rake::Task[OBJFILE].invoke
      runs.should == ["F"]
    end

    xit "test_create_with_source" do
      create_file(SRCFILE)
      remote "127.0.0.1"
      rule(/\.o$/ => ['.c']) do |t|
        t.fatal "--#{t.name}--"
        t.error "assert_equal #{t.name}"
        t.error "assert_equal #{t.source}"
      end
      ::Rake::Task[OBJFILE].invoke
      runs.should == [OBJFILE]
      @msg.should =~ /ERROR.*assert_equal #{OBJFILE}.*ERROR.*assert_equal #{SRCFILE}/m
    end

#pending do
    xit "test_single_dependent" do
      create_file(SRCFILE)
      remote "127.0.0.1"
      rule(/\.o$/ => '.c') do |t|
        @runs << t.name
      end
      remote
      ::Rake::Task[OBJFILE].invoke
      assert_equal [OBJFILE], @runs
    end

    xit "test_rule_can_be_created_by_string" do
      create_file(SRCFILE)
      remote "127.0.0.1"
      rule '.o' => ['.c'] do |t|
        @runs << t.name
      end
      remote
      ::Rake::Task[OBJFILE].invoke
      assert_equal [OBJFILE], @runs
    end

    xit "test_rule_prereqs_can_be_created_by_string" do
      create_file(SRCFILE)
      remote "127.0.0.1"
      rule '.o' => '.c' do |t|
        @runs << t.name
      end
      remote
      ::Rake::Task[OBJFILE].invoke
      assert_equal [OBJFILE], @runs
    end

    xit "test_plain_strings_as_dependents_refer_to_files" do
      create_file(SRCFILE)
      remote "127.0.0.1"
      rule '.o' => SRCFILE do |t|
        @runs << t.name
      end
      ::Rake::Task[OBJFILE].invoke
      assert_equal [OBJFILE], @runs
    end

    xit "test_file_names_beginning_with_dot_can_be_tricked_into_refering_to_file" do
      verbose(false) do
        chdir("testdata") do
          create_file('.foo')
          remote "127.0.0.1"
          rule '.o' => "./.foo" do |t|
            @runs << t.name
          end
          ::Rake::Task[OBJFILE].invoke
          assert_equal [OBJFILE], @runs
        end
      end
    end

    xit "test_file_names_beginning_with_dot_can_be_wrapped_in_lambda" do
      verbose(false) do
        chdir("testdata") do
          create_file(".foo")
          remote "127.0.0.1"
          rule '.o' => lambda{".foo"} do |t|
            @runs << "#{t.name} - #{t.source}"
          end
          Task[OBJFILE].invoke
          assert_equal ["#{OBJFILE} - .foo"], @runs
        end
      end
    end

    xit "test_file_names_containing_percent_can_be_wrapped_in_lambda" do
      verbose(false) do
        chdir("testdata") do
          create_file("foo%x")
          remote "127.0.0.1"
          rule '.o' => lambda{"foo%x"} do |t|
            @runs << "#{t.name} - #{t.source}"
          end
          Task[OBJFILE].invoke
          assert_equal ["#{OBJFILE} - foo%x"], @runs
        end
      end
    end

    xit "test_non_extension_rule_name_refers_to_file" do
      verbose(false) do
        chdir("testdata") do
          create_file("abc.c")
          remote "127.0.0.1"
          rule "abc" => '.c' do |t|
            @runs << t.name
          end
          Task["abc"].invoke
          assert_equal ["abc"], @runs
        end
      end
    end

    xit "test_pathmap_automatically_applies_to_name" do
      verbose(false) do
        chdir("testdata") do
          create_file("zzabc.c")
          remote "127.0.0.1"
          rule ".o" => 'zz%{x,a}n.c' do |t|
            @runs << "#{t.name} - #{t.source}"
          end
          Task["xbc.o"].invoke
          assert_equal ["xbc.o - zzabc.c"], @runs
        end
      end
    end

    xit "test_plain_strings_are_just_filenames" do
      verbose(false) do
        chdir("testdata") do
          create_file("plainname")
          remote "127.0.0.1"
          rule ".o" => 'plainname' do |t|
            @runs << "#{t.name} - #{t.source}"
          end
          Task["xbc.o"].invoke
          assert_equal ["xbc.o - plainname"], @runs
        end
      end
    end

    xit "test_rule_runs_when_explicit_task_has_no_actions" do
      create_file(SRCFILE)
      create_file(SRCFILE2)
      delete_file(OBJFILE)
      remote "127.0.0.1"
      rule '.o' => '.c' do |t|
        @runs << t.source
      end
      file OBJFILE => [SRCFILE2]
      Task[OBJFILE].invoke
      assert_equal [SRCFILE], @runs
    end

    xit "test_close_matches_on_name_do_not_trigger_rule" do
      create_file("testdata/x.c")
      rule '.o' => ['.c'] do |t|
        @runs << t.name
      end
      assert_exception(RuntimeError) { Task['testdata/x.obj'].invoke }
      assert_exception(RuntimeError) { Task['testdata/x.xyo'].invoke }
    end

    xit "test_rule_rebuilds_obj_when_source_is_newer" do
      create_timed_files(OBJFILE, SRCFILE)
      remote "127.0.0.1"
      rule(/\.o$/ => ['.c']) do
        @runs << :RULE
      end
      Task[OBJFILE].invoke
      assert_equal [:RULE], @runs
    end

    xit "test_rule_with_two_sources_runs_if_both_sources_are_present" do
      create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
      remote "127.0.0.1"
      rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}] do
        @runs << :RULE
      end
      Task[OBJFILE].invoke
      assert_equal [:RULE], @runs
    end

    xit "test_rule_with_two_sources_but_one_missing_does_not_run" do
      create_timed_files(OBJFILE, SRCFILE)
      delete_file(SRCFILE2)
      rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}] do
        @runs << :RULE
      end
      Task[OBJFILE].invoke
      assert_equal [], @runs
    end

    xit "test_rule_with_two_sources_builds_both_sources" do
      remote "127.0.0.1"
      task 'x.aa'
      task 'x.bb'
      rule '.a' => '.aa' do
        @runs << "A"
      end
      rule '.b' => '.bb' do
        @runs << "B"
      end
      rule ".c" => ['.a', '.b'] do
        @runs << "C"
      end
      Task["x.c"].invoke
      assert_equal ["A", "B", "C"], @runs.sort
    end

    xit "test_second_rule_runs_when_first_rule_doesnt" do
      create_timed_files(OBJFILE, SRCFILE)
      delete_file(SRCFILE2)
      remote "127.0.0.1"
      rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}] do
        @runs << :RULE1
      end
      rule OBJFILE => [lambda{SRCFILE}] do
        @runs << :RULE2
      end
      Task[OBJFILE].invoke
      assert_equal [:RULE2], @runs
    end

    xit "test_second_rule_doest_run_if_first_triggers" do
      create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
      remote "127.0.0.1"
      rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}] do
        @runs << :RULE1
      end
      rule OBJFILE => [lambda{SRCFILE}] do
        @runs << :RULE2
      end
      Task[OBJFILE].invoke
      assert_equal [:RULE1], @runs
    end

    xit "test_second_rule_doest_run_if_first_triggers_with_reversed_rules" do
      create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
      remote "127.0.0.1"
      rule OBJFILE => [lambda{SRCFILE}] do
        @runs << :RULE1
      end
      rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}] do
        @runs << :RULE2
      end
      Task[OBJFILE].invoke
      assert_equal [:RULE1], @runs
    end

    xit "test_rule_with_proc_dependent_will_trigger" do
    begin
      ran = false
      mkdir_p("testdata/src/jw")
      create_file("testdata/src/jw/X.java")
      remote "127.0.0.1"
      rule %r(classes/.*\.class) => [
        proc { |fn| fn.pathmap("%{classes,testdata/src}d/%n.java") }
      ] do |task|
        assert_equal task.name, 'classes/jw/X.class'
        assert_equal task.source, 'testdata/src/jw/X.java'
        @runs << :RULE
      end
      Task['classes/jw/X.class'].invoke
      assert_equal [:RULE], @runs
    ensure
      rm_r("testdata/src", :verbose=>false) rescue nil
    end
    end

    xit "test_proc_returning_lists_are_flattened_into_prereqs" do
    begin
      ran = false
      mkdir_p("testdata/flatten")
      create_file("testdata/flatten/a.txt")
      remote "127.0.0.1"
      task 'testdata/flatten/b.data' do |t|
        ran = true
        touch t.name, :verbose => false
      end
      rule '.html' =>
        proc { |fn|
        [
          fn.ext("txt"),
          "testdata/flatten/b.data"
        ]
      } do |task|
      end
      Task['testdata/flatten/a.html'].invoke
      assert ran, "Should have triggered flattened dependency"
    ensure
      rm_r("testdata/flatten", :verbose=>false) rescue nil
    end
    end

    xit "test_recursive_rules_will_work_as_long_as_they_terminate" do
      actions = []
      create_file("testdata/abc.xml")
      remote "127.0.0.1"
      rule '.y' => '.xml' do actions << 'y' end
      rule '.c' => '.y' do actions << 'c'end
      rule '.o' => '.c' do actions << 'o'end
      rule '.exe' => '.o' do actions << 'exe'end
      Task["testdata/abc.exe"].invoke
      assert_equal ['y', 'c', 'o', 'exe'], actions
    end
    
    xit "test_recursive_rules_that_dont_terminate_will_overflow" do
      create_file("testdata/a.a")
      prev = 'a'
      ('b'..'z').each do |letter|
        rule ".#{letter}" => ".#{prev}" do |t| puts "#{t.name}" end
        prev = letter
      end
      ex = assert_exception(Rake::RuleRecursionOverflowError) {
        Task["testdata/a.z"].invoke
      }
      assert_match(/a\.z => testdata\/a.y/, ex.message)
    end
#end
  end
  
#pending "some tests are still not reimplemented" do
  # test/lib/dsl_test.rb
  describe "DslTest" do
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    xit "test_dsl_toplevel_when_require_rake_dsl" do
      assert_nothing_raised {
        ruby '-I./lib', '-rrrake/dsl', '-e', 'task(:x) { }', :verbose => false
      }
    end
  end
  
  # test/functional/session_based_tests.rb
  describe "SessionBasedTests" do
    before :each do
      ::Rake.application.clear
      TestServer.msg
    end
    
    xit "test_by_default_rakelib_files_are_included" do
      in_environment('RAKE_SYSTEM' => 'test/data/sys') do
        rake '-T', 'extra'
      end
      assert_match %r{extra:extra}, @out
    end

    xit "test_dash_f_with_no_arg_foils_rakefile_lookup" do
      rake "-I test/data/rakelib -rtest1 -f"
      assert_match(/^TEST1$/, @out)
    end

    xit "test_dot_rake_files_can_be_loaded_with_dash_r" do
      rake "-I test/data/rakelib -rtest2 -f"
      assert_match(/^TEST2$/, @out)
    end

    xit "test_file_task_dependencies_scoped_by_namespaces" do
    begin
      in_environment("PWD" => "test/data/namespace") do
        rake "scopedep.rb"
        assert_match(/^PREPARE\nSCOPEDEP$/m, @out)
      end
    ensure
      remove_namespace_files
    end
    end
    
    xit "test_imports" do
      open("test/data/imports/static_deps", "w") do |f|
        f.puts 'puts "STATIC"'
      end
      FileUtils.rm_f "test/data/imports/dynamic_deps"
      in_environment("PWD" => "test/data/imports") do
        rake
      end
      assert File.exist?("test/data/imports/dynamic_deps"),
        "'dynamic_deps' file should exist"
      assert_match(/^FIRST$\s+^DYNAMIC$\s+^STATIC$\s+^OTHER$/, @out)
      assert_status
      FileUtils.rm_f "test/data/imports/dynamic_deps"
      FileUtils.rm_f "test/data/imports/static_deps"
    end

    xit "test_no_system" do
      in_environment('RAKE_SYSTEM' => 'test/data/sys') do
        rake '-G', "sys1"
      end
      assert_match %r{^Don't know how to build task}, @err # emacs wart: '
    end

    xit "test_rules_chaining_to_file_task" do
      remove_chaining_files
      in_environment("PWD" => "test/data/chains") do
        rake
      end
      assert File.exist?("test/data/chains/play.app"),
        "'play.app' file should exist"
      assert_status
      remove_chaining_files
    end
  end
#end
end
