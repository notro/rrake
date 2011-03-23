#
# Original Rake tests that won't run as remote tasks
# The tests are reimplemented in 'rake_tests_reimplemented/'
#

# These tests are not reimplemented:
#
#   DslTest#test_dsl_toplevel_when_require_rake_dsl
#     Does not test remote capability
#
#   DslTest#test_dsl_not_toplevel_by_default
#     Does not test remote capability
#
#   TestApplication#test_building_imported_files_on_demand
#     Need mocking object, hard to  test remotely. Doesn't test remote capability
#
#   TestApplicationOptions#test_require
#     Depends on requiring files. Can't be done twice. Doesn't test remote capability
#
#   TestClean#test_clean
#     Depends on requiring files. Can't be done twice. Doesn't test remote capability
#

###############################################################################
#
# test/lib/application_test.rb

# NameError: undefined local variable or method `mock' for Rake:Module
test_not_reimplemented :TestApplication, :test_building_imported_files_on_demand

# <false> is not true.
test_reimplemented :TestApplication, :test_good_run

# Depends on requiring files. Can't be done twice.
test_not_reimplemented :TestApplicationOptions, :test_require



###############################################################################
#
# test/lib/clean_test.rb

# Depends on requiring files.
test_not_reimplemented :TestClean, :test_clean



###############################################################################
#
# test/lib/task_test.rb
#

# TestTask
# Task actions need access to local variable in test method
test_reimplemented :TestTask, :test_create

# Task actions need access to local variable in test method
test_reimplemented :TestTask, :test_invoke

# Fail on Ruby 1.9
# NoMethodError: undefined method `line_no' for nil:NilClass
test_reimplemented :TestTask, :test_invoke_with_circular_dependencies

# Task actions need access to local variable in test method
test_reimplemented :TestTask, :test_no_double_invoke

# Task actions need access to local variable in test method
test_reimplemented :TestTask, :test_can_double_invoke_with_reenable

# Task actions need access to local variable in test method
test_reimplemented :TestTask, :test_multi_invocations

# <100> expected but was
test_reimplemented :TestTask, :test_timestamp_returns_now_if_all_prereqs_have_no_times


# TestTaskWithArguments
# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_arg_list_is_empty_if_no_args_given

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_tasks_can_access_arguments_as_hash

# Task actions need access to local variable 'notes' in test
test_reimplemented :TestTaskWithArguments, :test_actions_of_various_arity_are_ok_with_args

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_arguments_are_passed_to_block

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_extra_parameters_are_ignored

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_arguments_are_passed_to_all_blocks

# fails because action has curly brackets which is not supported
test_reimplemented :TestTaskWithArguments, :test_block_with_no_parameters_is_ok

# Task actions need access to local variable 'value' in test
test_reimplemented :TestTaskWithArguments, :test_named_args_are_passed_to_prereqs

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_args_not_passed_if_no_prereq_names

# assert_equal in task action
test_reimplemented :TestTaskWithArguments, :test_args_not_passed_if_no_arg_names



###############################################################################
#
# test/lib/definitions_test.rb

# Should be done.
# <false> is not true.
test_reimplemented :TestDefinitions, :test_file_task

# NameError: undefined local variable or method `runs' for Rake:Module
test_reimplemented :TestDefinitions, :test_implicit_file_dependencies

# NameError: undefined local variable or method `runs' for Rake:Module
test_reimplemented :TestDefinitions, :test_incremental_definitions

# Should be done.
# <false> is not true.
test_reimplemented :TestDefinitions, :test_task
  


###############################################################################
#
# test/lib/file_task_test.rb

# NoMethodError: undefined method `<<' for nil:NilClass
test_reimplemented :TestFileTask, :test_file_depends_on_task_depend_on_file

#T1 should be older
test_reimplemented :TestFileTask, :test_file_times_old_depends_on_new
  


###############################################################################
#
# test/lib/multitask_test.rb

# NoMethodError: undefined method `add_run' for Rake:Module
test_reimplemented :TestMultiTask, :test_all_multitasks_wait_on_slow_prerequisites

# NoMethodError: undefined method `add_run' for Rake:Module
test_reimplemented :TestMultiTask, :test_running_multitasks



###############################################################################
#
# test/lib/task_manager_test.rb

# NameError: undefined local variable or method `values' for Rake:Module
test_reimplemented :TestTaskManager, :test_correctly_scoped_prerequisites_are_invoked
  


###############################################################################
#
# test/lib/dsl_test.rb

# Exception raised:
# Class: <RuntimeError>
# Message: <"Command failed with status (1): [/usr/bin/ruby1.8 -I./lib -rrrake/dsl -e ta...]">
test_not_reimplemented :DslTest, :test_dsl_toplevel_when_require_rake_dsl

# Won't pass after application_test.rb has used handle_options which does Rake::DSL.include_in_top_scope
test_not_reimplemented :DslTest, :test_dsl_not_toplevel_by_default


###############################################################################
#
# test/functional/session_based_tests.rb

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </extra:extra/>.
test_reimplemented :SessionBasedTests, :test_by_default_rakelib_files_are_included

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST1$/>.
test_reimplemented :SessionBasedTests, :test_dash_f_with_no_arg_foils_rakefile_lookup

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST2$/>.
test_reimplemented :SessionBasedTests, :test_dot_rake_files_can_be_loaded_with_dash_r

# <"(in /home/notro/repos/rrake/test/data/namespace)\nPREPARE\n"> expected to be =~
# </^PREPARE\nSCOPEDEP$/m>.
test_reimplemented :SessionBasedTests, :test_file_task_dependencies_scoped_by_namespaces

# 'dynamic_deps' file should exist.
# <false> is not true.
test_reimplemented :SessionBasedTests, :test_imports

# <"rrake aborted!\nFailed.  Response code = 500.  Response message = Internal Server Error .\n/home/notro/repos/rrake/Rakefile:211:in `new'\n(See full trace by running task with --trace)\n"> expected to be =~
# </^Don't know how to build task/>.
test_reimplemented :SessionBasedTests, :test_no_system

# 'play.app' file should exist.
# <false> is not true.
test_reimplemented :SessionBasedTests, :test_rules_chaining_to_file_task



###############################################################################
#
# test/lib/file_task_test.rb

if Rake::Win32.windows?
  # Fails on Windows
  # RuntimeError: can't serialize proc, #source is nil
  test_reimplemented :TestDirectoryTask, :test_directory_win32
end
