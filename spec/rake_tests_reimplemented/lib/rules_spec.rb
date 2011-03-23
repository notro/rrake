require "test/filecreation"


describe "TestRules reimplemented" do
  include FileCreation
  
  SRCFILE  = "testdata/abc.c"
  SRCFILE2 =  "testdata/xyz.c"
  FTNFILE  = "testdata/abc.f"
  OBJFILE  = "testdata/abc.o"
  FOOFILE  = "testdata/foo"
  DOTFOOFILE = "testdata/.foo"

  before :all do
    TestServer.start
  end

  after :all do
    ::Rake.application.clear
    FileUtils.rm_f "testdata"
  end
  
  before :each do
    ::Rake.application.clear
    TestServer.msg
    @runs = nil
    FileList['testdata/*'].uniq.each do |f| FileUtils.rm_r(f, :verbose=>false) end
  end
  
  def runs
    return @runs unless @runs.nil?
    @runs = []
    @msg = TestServer.msg
    fatal = @msg.lines.select { |l| l.include? "FATAL"}
    fatal.each { |f| m = f.match(/--(.+)--/); @runs << m[1] if m }
    @runs
  end
  
  it "test_multiple_rules1" do
    create_file(FTNFILE)
    delete_file(SRCFILE)
    delete_file(OBJFILE)
    rule(/\.o$/ => ['.c']) do |t| t.fatal "--C--" end
    rule(/\.o$/ => ['.f']) do |t| t.fatal "--F--" end
    remote "127.0.0.1"
    t = ::Rake::Task[OBJFILE]
    t.invoke
    ::Rake::Task[OBJFILE].invoke
    runs.should == ["F"]
  end

  it "test_multiple_rules2" do
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

  it "test_create_with_source" do
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

  it "test_single_dependent" do
    create_file(SRCFILE)
    remote "127.0.0.1"
    rule(/\.o$/ => '.c') do |t|
      t.fatal "--#{t.name}--"
    end
    remote
    ::Rake::Task[OBJFILE].invoke
    runs.should == [OBJFILE]
  end

  it "test_rule_can_be_created_by_string" do
    create_file(SRCFILE)
    remote "127.0.0.1"
    rule '.o' => ['.c'] do |t|
      t.fatal "--#{t.name}--"
    end
    remote
    ::Rake::Task[OBJFILE].invoke
    runs.should == [OBJFILE]
  end

  it "test_rule_prereqs_can_be_created_by_string" do
    create_file(SRCFILE)
    remote "127.0.0.1"
    rule '.o' => '.c' do |t|
      t.fatal "--#{t.name}--"
    end
    remote
    ::Rake::Task[OBJFILE].invoke
    runs.should == [OBJFILE]
  end

  it "test_plain_strings_as_dependents_refer_to_files" do
    create_file(SRCFILE)
    remote "127.0.0.1"
    rule '.o' => SRCFILE do |t|
      t.fatal "--#{t.name}--"
    end
    remote
    ::Rake::Task[OBJFILE].invoke
    runs.should == [OBJFILE]
  end

  it "test_file_names_beginning_with_dot_can_be_tricked_into_refering_to_file" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file('testdata/.foo')
        rule '.o' => "./.foo" do |t|
          t.fatal "--#{t.name}--"
        end
        remote "127.0.0.1"
        ::Rake::Task[OBJFILE].invoke
        runs.should == [OBJFILE]
      end
    end
  end

  it "test_file_names_beginning_with_dot_can_be_wrapped_in_lambda" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file("testdata/.foo")
        l = lambda{".foo"}
        rule '.o' => l do |t|
          t.fatal "--#{t.name} - #{t.source}--"
        end
        remote "127.0.0.1"
        ::Rake::Task[OBJFILE].invoke
        runs.should == ["#{OBJFILE} - .foo"]
      end
    end
  end

  it "test_file_names_containing_percent_can_be_wrapped_in_lambda" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file("testdata/foo%x")
        l = lambda{"foo%x"}
        rule '.o' => l do |t|
          t.fatal "--#{t.name} - #{t.source}--"
        end
        remote "127.0.0.1"
        ::Rake::Task[OBJFILE].invoke
        runs.should == ["#{OBJFILE} - foo%x"]
      end
    end
  end

  it "test_non_extension_rule_name_refers_to_file" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file("testdata/abc.c")
        rule "abc" => '.c' do |t|
          t.fatal "--#{t.name}--"
        end
        remote "127.0.0.1"
        ::Rake::Task["abc"].invoke
        runs.should == ["abc"]
      end
    end
  end

  it "test_pathmap_automatically_applies_to_name" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file("testdata/zzabc.c")
        rule ".o" => 'zz%{x,a}n.c' do |t|
          t.fatal "--#{t.name} - #{t.source}--"
        end
        remote "127.0.0.1"
        ::Rake::Task["xbc.o"].invoke
        runs.should == ["xbc.o - zzabc.c"]
      end
    end
  end

  it "test_plain_strings_are_just_filenames" do
    verbose(false) do
      TestServer.chdir("testdata") do
        create_file("testdata/plainname")
        rule ".o" => 'plainname' do |t|
          t.fatal "--#{t.name} - #{t.source}--"
        end
        remote "127.0.0.1"
        ::Rake::Task["xbc.o"].invoke
        runs.should == ["xbc.o - plainname"]
      end
    end
  end

  it "test_rule_runs_when_explicit_task_has_no_actions" do
    create_file(SRCFILE)
    create_file(SRCFILE2)
    delete_file(OBJFILE)
    rule '.o' => '.c' do |t|
      t.fatal "--#{t.source}--"
    end
    remote "127.0.0.1"
    file OBJFILE => [SRCFILE2]
    ::Rake::Task[OBJFILE].invoke
    runs.should == [SRCFILE]
  end

  it "test_close_matches_on_name_do_not_trigger_rule" do
    create_file("testdata/x.c")
    remote "127.0.0.1"
    rule '.o' => ['.c'] do |t|
      t.fatal "--#{t.name}--"
    end
    expect{ ::Rake::Task['testdata/x.obj'].invoke }.to raise_error RuntimeError
    expect{ ::Rake::Task['testdata/x.xyo'].invoke }.to raise_error RuntimeError
  end

  it "test_rule_rebuilds_obj_when_source_is_newer" do
    create_timed_files(OBJFILE, SRCFILE)
    rule(/\.o$/ => ['.c']) do |t|
      t.fatal "--:RULE--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == [":RULE"]
  end

 it "test_rule_with_two_sources_runs_if_both_sources_are_present" do
    create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
    # proc_source can't handle a lambda on the same line as the beginning do of the action
    rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}
    ] do |t|
      t.fatal "--:RULE--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == [":RULE"]
  end

  it "test_rule_with_two_sources_but_one_missing_does_not_run" do
    create_timed_files(OBJFILE, SRCFILE)
    delete_file(SRCFILE2)
    ls = 
    rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}
    ] do |t|
      t.fatal "--:RULE--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == []
  end

  it "test_rule_with_two_sources_builds_both_sources" do
    remote "127.0.0.1"
    task 'x.aa'
    remote
    task 'x.bb'
    rule '.a' => '.aa' do |t|
      t.fatal "--A--"
    end
    rule '.b' => '.bb' do |t|
      t.fatal "--B--"
    end
    rule ".c" => ['.a', '.b'] do |t|
      t.fatal "--C--"
    end
    remote
    ::Rake::Task["x.c"].invoke
    runs.should == ["A", "B", "C"]
  end

  it "test_second_rule_runs_when_first_rule_doesnt" do
    create_timed_files(OBJFILE, SRCFILE)
    delete_file(SRCFILE2)
    rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}
    ] do |t|
      t.fatal "--:RULE1--"
    end
    ls = [lambda{SRCFILE}]
    rule OBJFILE => ls do |t|
      t.fatal "--:RULE2--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == [":RULE2"]
  end

  it "test_second_rule_doest_run_if_first_triggers" do
    create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
    rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}
    ] do |t|
      t.fatal "--:RULE1--"
    end
    ls = [lambda{SRCFILE}]
    rule OBJFILE => ls do |t|
      t.fatal "--:RULE2--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == [":RULE1"]
  end

  it "test_second_rule_doest_run_if_first_triggers_with_reversed_rules" do
    create_timed_files(OBJFILE, SRCFILE, SRCFILE2)
    rule OBJFILE => [lambda{SRCFILE}
    ] do |t|
      t.fatal "--:RULE1--"
    end
    rule OBJFILE => [lambda{SRCFILE}, lambda{SRCFILE2}
    ] do |t|
      t.fatal "--:RULE2--"
    end
    remote "127.0.0.1"
    ::Rake::Task[OBJFILE].invoke
    runs.should == [":RULE1"]
  end

  it "test_rule_with_proc_dependent_will_trigger" do
  begin
    mkdir_p("testdata/src/jw")
    create_file("testdata/src/jw/X.java")
    rule %r(classes/.*\.class) => [
      proc { |fn| fn.pathmap("%{classes,testdata/src}d/%n.java") }
    ] do |t|
      t.error "assert_equal #{t.name}"
      t.error "assert_equal #{t.source}"
      t.fatal "--:RULE--"
    end
    remote "127.0.0.1"
    ::Rake::Task['classes/jw/X.class'].invoke
    runs.should == [":RULE"]
    @msg.should =~ /ERROR.*assert_equal classes\/jw\/X.class.*ERROR.*assert_equal testdata\/src\/jw\/X.java/m
  ensure
    rm_r("testdata/src", :verbose=>false) rescue nil
  end
  end

  it "test_proc_returning_lists_are_flattened_into_prereqs" do
  begin
    mkdir_p("testdata/flatten")
    create_file("testdata/flatten/a.txt")
    remote "127.0.0.1"
    task 'testdata/flatten/b.data' do |t|
      t.fatal "--ran--"
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
    remote
    ::Rake::Task['testdata/flatten/a.html'].invoke
    runs.should == ["ran"]
  ensure
    rm_r("testdata/flatten", :verbose=>false) rescue nil
  end
  end

  it "test_recursive_rules_will_work_as_long_as_they_terminate" do
    create_file("testdata/abc.xml")
    rule '.y' => '.xml' do |t| t.fatal '--y--' end
    rule '.c' => '.y' do |t| t.fatal '--c--' end
    rule '.o' => '.c' do |t| t.fatal '--o--' end
    rule '.exe' => '.o' do |t| t.fatal '--exe--' end
    remote "127.0.0.1"
    ::Rake::Task["testdata/abc.exe"].invoke
    runs.should == ['y', 'c', 'o', 'exe']
  end
  
  it "test_recursive_rules_that_dont_terminate_will_overflow" do
    create_file("testdata/a.a")
    prev = 'a'
    ('b'..'z').each do |letter|
      rule ".#{letter}" => ".#{prev}" do |t| t.fatal "#{t.name}" end
      prev = letter
    end
    expect{ ::Rake::Task["testdata/a.z"].invoke }.to raise_error ::Rake::RuleRecursionOverflowError, /a\.z => testdata\/a.y/
  end
end
