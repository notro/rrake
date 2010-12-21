--- !ruby/object:Gem::Specification 
name: rrake
version: !ruby/object:Gem::Version 
  hash: 393
  prerelease: false
  segments: 
  - 0
  - 8
  - 99
  - 5
  version: 0.8.99.5
platform: ruby
authors: 
- Noralf Tronnes
autorequire: 
bindir: bin
cert_chain: []

date: 2010-12-21 00:00:00 +01:00
default_executable: rrake
dependencies: []

description: "      Remote Rake extends rake to run tasks on remote machines.\n"
email: notro@tronnes.org
executables: 
- rrake
extensions: []

extra_rdoc_files: 
- README.rdoc
- MIT-LICENSE
- TODO
- CHANGES
- doc/glossary.rdoc
- doc/release_notes/rake-0.8.4.rdoc
- doc/release_notes/rake-0.7.3.rdoc
- doc/release_notes/rake-0.7.1.rdoc
- doc/release_notes/rake-0.6.0.rdoc
- doc/release_notes/rake-0.5.4.rdoc
- doc/release_notes/rake-0.8.5.rdoc
- doc/release_notes/rake-0.8.2.rdoc
- doc/release_notes/rake-0.8.0.rdoc
- doc/release_notes/rake-0.8.6.rdoc
- doc/release_notes/rake-0.7.2.rdoc
- doc/release_notes/rake-0.7.0.rdoc
- doc/release_notes/rake-0.5.0.rdoc
- doc/release_notes/rake-0.8.3.rdoc
- doc/release_notes/rake-0.8.7.rdoc
- doc/release_notes/rake-0.5.3.rdoc
- doc/release_notes/rake-0.4.14.rdoc
- doc/release_notes/rake-0.4.15.rdoc
- doc/rakefile.rdoc
- doc/rational.rdoc
- doc/proto_rake.rdoc
- doc/command_line_usage.rdoc
files: 
- install.rb
- CHANGES
- README.rdoc
- Rakefile
- TODO
- MIT-LICENSE
- bin/rrake
- lib/rrake.rb
- lib/rrake/win32.rb
- lib/rrake/name_space.rb
- lib/rrake/default_loader.rb
- lib/rrake/file_creation_task.rb
- lib/rrake/file_utils_ext.rb
- lib/rrake/task_arguments.rb
- lib/rrake/application.rb
- lib/rrake/task_manager.rb
- lib/rrake/rule_recursion_overflow_error.rb
- lib/rrake/file_list.rb
- lib/rrake/multi_task.rb
- lib/rrake/rake_module.rb
- lib/rrake/clean.rb
- lib/rrake/pseudo_status.rb
- lib/rrake/ext/string.rb
- lib/rrake/ext/module.rb
- lib/rrake/ext/time.rb
- lib/rrake/gempackagetask.rb
- lib/rrake/classic_namespace.rb
- lib/rrake/environment.rb
- lib/rrake/file_utils.rb
- lib/rrake/alt_system.rb
- lib/rrake/version.rb
- lib/rrake/dsl.rb
- lib/rrake/rake_test_loader.rb
- lib/rrake/ruby182_test_unit_fix.rb
- lib/rrake/runtest.rb
- lib/rrake/file_task.rb
- lib/rrake/invocation_chain.rb
- lib/rrake/packagetask.rb
- lib/rrake/task.rb
- lib/rrake/cloneable.rb
- lib/rrake/require_rrake.rb
- lib/rrake/testtask.rb
- lib/rrake/invocation_exception_mixin.rb
- lib/rrake/contrib/sys.rb
- lib/rrake/contrib/rubyforgepublisher.rb
- lib/rrake/contrib/compositepublisher.rb
- lib/rrake/contrib/sshpublisher.rb
- lib/rrake/contrib/publisher.rb
- lib/rrake/contrib/ftptools.rb
- lib/rrake/early_time.rb
- lib/rrake/rdoctask.rb
- lib/rrake/loaders/makefile.rb
- lib/rrake/tasklib.rb
- lib/rrake/task_argument_error.rb
- lib/rrake/dsl_definition.rb
- test/rake_test_setup.rb
- test/shellcommand.rb
- test/reqfile.rb
- test/check_no_expansion.rb
- test/capture_stdout.rb
- test/functional/functional_test.rb
- test/functional/session_based_tests.rb
- test/data/rakelib/test1.rb
- test/data/rbext/rakefile.rb
- test/ruby_version_test.rb
- test/in_environment.rb
- test/test_helper.rb
- test/check_expansion.rb
- test/reqfile2.rb
- test/lib/win32_test.rb
- test/lib/require_test.rb
- test/lib/package_task_test.rb
- test/lib/test_task_test.rb
- test/lib/namespace_test.rb
- test/lib/environment_test.rb
- test/lib/extension_test.rb
- test/lib/rake_test.rb
- test/lib/rules_test.rb
- test/lib/dsl_test.rb
- test/lib/task_manager_test.rb
- test/lib/rdoc_task_test.rb
- test/lib/multitask_test.rb
- test/lib/task_arguments_test.rb
- test/lib/pseudo_status_test.rb
- test/lib/earlytime_test.rb
- test/lib/pathmap_test.rb
- test/lib/top_level_functions_test.rb
- test/lib/invocation_chain_test.rb
- test/lib/tasklib_test.rb
- test/lib/ftp_test.rb
- test/lib/clean_test.rb
- test/lib/makefile_loader_test.rb
- test/lib/file_task_test.rb
- test/lib/filelist_test.rb
- test/lib/definitions_test.rb
- test/lib/fileutils_test.rb
- test/lib/application_test.rb
- test/lib/file_creation_task_test.rb
- test/lib/testtask_test.rb
- test/lib/task_test.rb
- test/filecreation.rb
- test/contrib/test_sys.rb
- test/data/imports/deps.mf
- test/data/sample.mf
- test/data/namespace/Rakefile
- test/data/dryrun/Rakefile
- test/data/chains/Rakefile
- test/data/file_creation_task/Rakefile
- test/data/unittest/Rakefile
- test/data/verbose/Rakefile
- test/data/default/Rakefile
- test/data/statusreturn/Rakefile
- test/data/imports/Rakefile
- test/data/multidesc/Rakefile
- test/data/comments/Rakefile
- test/data/unittest/subdir
- doc/glossary.rdoc
- doc/jamis.rb
- doc/rake.1.gz
- doc/release_notes
- doc/release_notes/rake-0.8.4.rdoc
- doc/release_notes/rake-0.7.3.rdoc
- doc/release_notes/rake-0.7.1.rdoc
- doc/release_notes/rake-0.6.0.rdoc
- doc/release_notes/rake-0.5.4.rdoc
- doc/release_notes/rake-0.8.5.rdoc
- doc/release_notes/rake-0.8.2.rdoc
- doc/release_notes/rake-0.8.0.rdoc
- doc/release_notes/rake-0.8.6.rdoc
- doc/release_notes/rake-0.7.2.rdoc
- doc/release_notes/rake-0.7.0.rdoc
- doc/release_notes/rake-0.5.0.rdoc
- doc/release_notes/rake-0.8.3.rdoc
- doc/release_notes/rake-0.8.7.rdoc
- doc/release_notes/rake-0.5.3.rdoc
- doc/release_notes/rake-0.4.14.rdoc
- doc/release_notes/rake-0.4.15.rdoc
- doc/rakefile.rdoc
- doc/rational.rdoc
- doc/proto_rake.rdoc
- doc/example
- doc/example/Rakefile2
- doc/example/b.c
- doc/example/a.c
- doc/example/Rakefile1
- doc/example/main.c
- doc/command_line_usage.rdoc
has_rdoc: true
homepage: http://rrake.rubyforge.org
licenses: []

post_install_message: 
rdoc_options: 
- --line-numbers
- --inline-source
- --main
- README.rdoc
- --title
- Remote Rake
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
requirements: []

rubyforge_project: rrake
rubygems_version: 1.3.7
signing_key: 
specification_version: 3
summary: Ruby based make-like utility.
test_files: []

