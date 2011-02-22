#
# Tests that currently doesn't run as remote tasks
#


###############################################################################
#
# test/lib/application_test.rb

# NameError: undefined local variable or method `mock' for Rake:Module
skip :TestApplication, :test_building_imported_files_on_demand

# <false> is not true.
skip :TestApplication, :test_good_run



###############################################################################
#
# test/lib/task_test.rb
#
# The skipped tests are reimplemented as rspecs in spec/lib_task_remote_spec.rb, except for test_filelists_can_be_prerequisites

# TestTask
# Task actions need access to local variable in test method
skip :TestTask, :test_create

# Task actions need access to local variable in test method
skip :TestTask, :test_invoke

# Fail on Ruby 1.9
# NoMethodError: undefined method `line_no' for nil:NilClass
skip :TestTask, :test_invoke_with_circular_dependencies

# Task actions need access to local variable in test method
skip :TestTask, :test_no_double_invoke

# Task actions need access to local variable in test method
skip :TestTask, :test_can_double_invoke_with_reenable

# Task actions need access to local variable in test method
skip :TestTask, :test_multi_invocations

# Nestful::ServerError: Failed.  Response code = 500.  Response message = Internal Server Error .
skip :TestTask, :test_filelists_can_be_prerequisites

# <100> expected but was
skip :TestTask, :test_timestamp_returns_now_if_all_prereqs_have_no_times


# TestTaskWithArguments
# assert_equal in task action
skip :TestTaskWithArguments, :test_arg_list_is_empty_if_no_args_given

# assert_equal in task action
skip :TestTaskWithArguments, :test_tasks_can_access_arguments_as_hash

# Task actions need access to local variable 'notes' in test
skip :TestTaskWithArguments, :test_actions_of_various_arity_are_ok_with_args

# assert_equal in task action
skip :TestTaskWithArguments, :test_arguments_are_passed_to_block

# assert_equal in task action
skip :TestTaskWithArguments, :test_extra_parameters_are_ignored

# assert_equal in task action
skip :TestTaskWithArguments, :test_arguments_are_passed_to_all_blocks

# fails because action has curly brackets which is not supported
skip :TestTaskWithArguments, :test_block_with_no_parameters_is_ok

# Task actions need access to local variable 'value' in test
skip :TestTaskWithArguments, :test_named_args_are_passed_to_prereqs

# assert_equal in task action
skip :TestTaskWithArguments, :test_args_not_passed_if_no_prereq_names

# assert_equal in task action
skip :TestTaskWithArguments, :test_args_not_passed_if_no_arg_names



###############################################################################
#
# test/lib/definitions_test.rb

# Should be done.
# <false> is not true.
skip :TestDefinitions, :test_file_task

# NameError: undefined local variable or method `runs' for Rake:Module
skip :TestDefinitions, :test_implicit_file_dependencies

# NameError: undefined local variable or method `runs' for Rake:Module
skip :TestDefinitions, :test_incremental_definitions

# Should be done.
# <false> is not true.
skip :TestDefinitions, :test_task
  


###############################################################################
#
# test/lib/file_task_test.rb

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestFileTask, :test_file_depends_on_task_depend_on_file

#T1 should be older
skip :TestFileTask, :test_file_times_old_depends_on_new
  


###############################################################################
#
# test/lib/multitask_test.rb

# NoMethodError: undefined method `add_run' for Rake:Module
skip :TestMultiTask, :test_all_multitasks_wait_on_slow_prerequisites

# NoMethodError: undefined method `add_run' for Rake:Module
skip :TestMultiTask, :test_running_multitasks



###############################################################################
#
# test/lib/task_manager_test.rb

# NameError: undefined local variable or method `values' for Rake:Module
skip :TestTaskManager, :test_correctly_scoped_prerequisites_are_invoked
  


###############################################################################
#
# test/lib/rules_test.rb

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_create_with_source

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_file_names_beginning_with_dot_can_be_tricked_into_refering_to_file

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_file_names_beginning_with_dot_can_be_wrapped_in_lambda

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_file_names_containing_percent_can_be_wrapped_in_lambda

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_multiple_rules1

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_multiple_rules2

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_non_extension_rule_name_refers_to_file

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_pathmap_automatically_applies_to_name

# RuntimeError: can't serialize proc, #source is nil
skip :TestRules, :test_plain_strings_are_just_filenames

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_plain_strings_as_dependents_refer_to_files

# NoMethodError: undefined method `line_no' for nil:NilClass
skip :TestRules, :test_proc_returning_lists_are_flattened_into_prereqs

# NameError: undefined local variable or method `actions' for Rake:Module
skip :TestRules, :test_recursive_rules_will_work_as_long_as_they_terminate

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_rule_can_be_created_by_string

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_rule_prereqs_can_be_created_by_string

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_rule_rebuilds_obj_when_source_is_newer

# <["testdata/abc.c"]> expected but was
# <[]>.
skip :TestRules, :test_rule_runs_when_explicit_task_has_no_actions

# NoMethodError: undefined method `assert_equal' for Rake:Module
skip :TestRules, :test_rule_with_proc_dependent_will_trigger

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_rule_with_two_sources_builds_both_sources

# <[:RULE]> expected but was
# <[]>.
skip :TestRules, :test_rule_with_two_sources_runs_if_both_sources_are_present

# <[:RULE1]> expected but was
# <[]>.
skip :TestRules, :test_second_rule_doest_run_if_first_triggers

# <[:RULE1]> expected but was
# <[]>.
skip :TestRules, :test_second_rule_doest_run_if_first_triggers_with_reversed_rules

# <[:RULE2]> expected but was
# <[]>.
skip :TestRules, :test_second_rule_runs_when_first_rule_doesnt

# NoMethodError: undefined method `<<' for nil:NilClass
skip :TestRules, :test_single_dependent



###############################################################################
#
# test/lib/dsl_test.rb

# Exception raised:
# Class: <RuntimeError>
# Message: <"Command failed with status (1): [/usr/bin/ruby1.8 -I./lib -rrrake/dsl -e ta...]">
skip :DslTest, :test_dsl_toplevel_when_require_rake_dsl



###############################################################################
#
# test/functional/session_based_tests.rb

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </extra:extra/>.
skip :SessionBasedTests, :test_by_default_rakelib_files_are_included

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST1$/>.
skip :SessionBasedTests, :test_dash_f_with_no_arg_foils_rakefile_lookup

# <"(in /home/notro/repos/rrake)\n"> expected to be =~
# </^TEST2$/>.
skip :SessionBasedTests, :test_dot_rake_files_can_be_loaded_with_dash_r

# <"(in /home/notro/repos/rrake/test/data/namespace)\nPREPARE\n"> expected to be =~
# </^PREPARE\nSCOPEDEP$/m>.
skip :SessionBasedTests, :test_file_task_dependencies_scoped_by_namespaces

# 'dynamic_deps' file should exist.
# <false> is not true.
skip :SessionBasedTests, :test_imports

# <"rrake aborted!\nFailed.  Response code = 500.  Response message = Internal Server Error .\n/home/notro/repos/rrake/Rakefile:211:in `new'\n(See full trace by running task with --trace)\n"> expected to be =~
# </^Don't know how to build task/>.
skip :SessionBasedTests, :test_no_system

# 'play.app' file should exist.
# <false> is not true.
skip :SessionBasedTests, :test_rules_chaining_to_file_task



###############################################################################
#
# test/lib/file_task_test.rb

if Rake::Win32.windows?
  # Fails on Windows
  # RuntimeError: can't serialize proc, #source is nil
  skip :TestDirectoryTask, :test_directory_win32
end
