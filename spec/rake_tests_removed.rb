#
# Original Rake tests that won't run as remote tasks
# The tests are reimplemented in 'rake_tests_reimplemented/'
#

# These test are not reimplemented:
#   DslTest.test_dsl_toplevel_when_require_rake_dsl: Doesn't test remote capability


###############################################################################
#
# test/lib/application_test.rb

# NameError: undefined local variable or method `mock' for Rake:Module
remove_test :TestApplication, :test_building_imported_files_on_demand

# <false> is not true.
remove_test :TestApplication, :test_good_run



###############################################################################
#
# test/lib/task_test.rb
#

# TestTask
# Task actions need access to local variable in test method
remove_test :TestTask, :test_create

# Task actions need access to local variable in test method
remove_test :TestTask, :test_invoke

# Fail on Ruby 1.9
# NoMethodError: undefined method `line_no' for nil:NilClass
remove_test :TestTask, :test_invoke_with_circular_dependencies

# Task actions need access to local variable in test method
remove_test :TestTask, :test_no_double_invoke

# Task actions need access to local variable in test method
remove_test :TestTask, :test_can_double_invoke_with_reenable

# Task actions need access to local variable in test method
remove_test :TestTask, :test_multi_invocations

# <100> expected but was
remove_test :TestTask, :test_timestamp_returns_now_if_all_prereqs_have_no_times


# TestTaskWithArguments
# assert_equal in task action
remove_test :TestTaskWithArguments, :test_arg_list_is_empty_if_no_args_given

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_tasks_can_access_arguments_as_hash

# Task actions need access to local variable 'notes' in test
remove_test :TestTaskWithArguments, :test_actions_of_various_arity_are_ok_with_args

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_arguments_are_passed_to_block

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_extra_parameters_are_ignored

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_arguments_are_passed_to_all_blocks

# fails because action has curly brackets which is not supported
remove_test :TestTaskWithArguments, :test_block_with_no_parameters_is_ok

# Task actions need access to local variable 'value' in test
remove_test :TestTaskWithArguments, :test_named_args_are_passed_to_prereqs

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_args_not_passed_if_no_prereq_names

# assert_equal in task action
remove_test :TestTaskWithArguments, :test_args_not_passed_if_no_arg_names



###############################################################################
#
# test/lib/definitions_test.rb

# Should be done.
# <false> is not true.
remove_test :TestDefinitions, :test_file_task

# NameError: undefined local variable or method `runs' for Rake:Module
remove_test :TestDefinitions, :test_implicit_file_dependencies

# NameError: undefined local variable or method `runs' for Rake:Module
remove_test :TestDefinitions, :test_incremental_definitions

# Should be done.
# <false> is not true.
remove_test :TestDefinitions, :test_task
  


###############################################################################
#
# test/lib/file_task_test.rb

# NoMethodError: undefined method `<<' for nil:NilClass
remove_test :TestFileTask, :test_file_depends_on_task_depend_on_file

#T1 should be older
remove_test :TestFileTask, :test_file_times_old_depends_on_new
  


###############################################################################
#
# test/lib/multitask_test.rb

# NoMethodError: undefined method `add_run' for Rake:Module
remove_test :TestMultiTask, :test_all_multitasks_wait_on_slow_prerequisites

# NoMethodError: undefined method `add_run' for Rake:Module
remove_test :TestMultiTask, :test_running_multitasks

class TestMultiTask
  # Silence: No tests were specified.
  def test_dummy
  end
end


###############################################################################
#
# test/lib/task_manager_test.rb

# NameError: undefined local variable or method `values' for Rake:Module
remove_test :TestTaskManager, :test_correctly_scoped_prerequisites_are_invoked
  


###############################################################################
#
# test/lib/dsl_test.rb

# Exception raised:
# Class: <RuntimeError>
# Message: <"Command failed with status (1): [/usr/bin/ruby1.8 -I./lib -rrrake/dsl -e ta...]">
remove_test :DslTest, :test_dsl_toplevel_when_require_rake_dsl



###############################################################################
#
# test/functional/session_based_tests.rb

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </extra:extra/>.
remove_test :SessionBasedTests, :test_by_default_rakelib_files_are_included

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST1$/>.
remove_test :SessionBasedTests, :test_dash_f_with_no_arg_foils_rakefile_lookup

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST2$/>.
remove_test :SessionBasedTests, :test_dot_rake_files_can_be_loaded_with_dash_r

# <"(in /home/notro/repos/rrake/test/data/namespace)\nPREPARE\n"> expected to be =~
# </^PREPARE\nSCOPEDEP$/m>.
remove_test :SessionBasedTests, :test_file_task_dependencies_scoped_by_namespaces

# 'dynamic_deps' file should exist.
# <false> is not true.
remove_test :SessionBasedTests, :test_imports

# <"rrake aborted!\nFailed.  Response code = 500.  Response message = Internal Server Error .\n/home/notro/repos/rrake/Rakefile:211:in `new'\n(See full trace by running task with --trace)\n"> expected to be =~
# </^Don't know how to build task/>.
remove_test :SessionBasedTests, :test_no_system

# 'play.app' file should exist.
# <false> is not true.
remove_test :SessionBasedTests, :test_rules_chaining_to_file_task



###############################################################################
#
# test/lib/file_task_test.rb

if Rake::Win32.windows?
  # Fails on Windows
  # RuntimeError: can't serialize proc, #source is nil
  remove_test :TestDirectoryTask, :test_directory_win32
end
