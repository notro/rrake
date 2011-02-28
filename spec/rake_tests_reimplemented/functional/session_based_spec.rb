# test/functional/session_based_tests.rb

SESSION_LOADED = begin
  require 'session'
  true
rescue LoadError
  false
end


describe "SessionBasedTests" do
  include InEnvironment
  
  RUBY_COMMAND = 'ruby'
  
  before :all do
    @verbose = ! ENV['VERBOSE'].nil?
    if @verbose
      puts "\n--------------------------------------------------------------------"
      puts "  Test: #{File.basename __FILE__}\n\n"
    end
    TestServer.start
    @rake_path = File.expand_path("bin/rrake")
    lib_path = File.expand_path("lib")
    @ruby_options = ["-I#{lib_path}", "-I."]
  end
  
  after :all do
    ::Rake.application.clear
    if @verbose
      puts "\n\n#{TestServer.logfile.path}"
      puts TestServer.msg_all if ENV['DEBUG']
      puts "--------------------------------------------------------------------"
    end
    rm_f "testdata"
  end
  
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

  it "test_rules_chaining_to_file_task" do
    remove_chaining_files
    in_environment("PWD" => "test/data/chains") do
      rake
    end
    File.exist?("test/data/chains/play.app").should == true
    @status.should == 0
    remove_chaining_files
  end
  
  def remove_chaining_files
    %w(play.scpt play.app base).each do |fn|
      FileUtils.rm_f File.join("test/data/chains", fn)
    end
  end
  
  def remove_namespace_files
    %w(scopedep.rb).each do |fn|
      FileUtils.rm_f File.join("test/data/namespace", fn)
    end
  end
  
  # Run a shell Ruby command with command line options (using the
  # default test options). Output is captured in @out, @err and
  # @status.
  def ruby(*option_list)
    run_ruby(@ruby_options + option_list)
  end

  # Run a command line rake with the give rake options.  Default
  # command line ruby options are included.  Output is captured in
  # @out, @err and @status.
  def rake(*rake_options)
    run_ruby @ruby_options + [@rake_path] + rake_options
  end

  # Low level ruby command runner ...
  def run_ruby(option_list)
    shell = Session::Shell.new
    command = "#{RUBY_COMMAND} " + option_list.join(' ')
    puts "COMMAND: [#{command}]" if @verbose
    @out, @err = shell.execute command
    @status = shell.exit_status
    puts "STATUS:  [#{@status}]" if @verbose
    puts "OUTPUT:  [#{@out}]" if @verbose
    puts "ERROR:   [#{@err}]" if @verbose
    puts "PWD:     [#{Dir.pwd}]" if @verbose
    shell.close
  end
end if SESSION_LOADED
