#!/usr/bin/env ruby

RUBY_VERSION_FLOAT = "#{RUBY_VERSION.to_i}.#{RUBY_VERSION.split('.')[1].to_i}#{RUBY_VERSION.split('.')[2].to_i}".to_f

require 'rrake'


PENDING_TESTS = []

require 'test/unit/ui/console/testrunner' if RUBY_VERSION_FLOAT < 1.9
module Test
  module Unit
    module UI
      module Console
        class TestRunner
          def finished(elapsed_time)
            nl
            output("Finished in #{elapsed_time} seconds.")
            @faults.each_with_index do |fault, index|
              nl
              output("%3d) %s" % [index + 1, fault.long_display])
            end
            nl
            output_single(@result)
            output(", #{PENDING_TESTS.size} skips")
          end
          
          def test_finished(name)
            unless (@already_outputted)
              if PENDING_TESTS.include? name
                output_single("S", PROGRESS_ONLY) 
              else
                output_single(".", PROGRESS_ONLY) 
              end
            end
            nl(VERBOSE)
            @already_outputted = false
          end
        end
      end
    end
  end
end if RUBY_VERSION_FLOAT < 1.9

# Don't print all the pending tests
require 'minitest/unit' if RUBY_VERSION_FLOAT >= 1.9
module MiniTest
  class Unit
    alias_method :orig_puke, :puke
    def puke klass, meth, e
      if e.is_a? MiniTest::Skip
        @skips += 1
        "S"
      else
        orig_puke klass, meth, e
      end
    end
  end
end if RUBY_VERSION_FLOAT >= 1.9


# Mark a test as pending/skipped
def skip(klass, name)
  if Object.const_defined?(klass)
    PENDING_TESTS << "#{name}(#{klass})"
    if RUBY_VERSION_FLOAT < 1.9
      eval "class #{klass}\n  undef #{name}\n  def #{name}\n  \nend\nend"
    else
      eval "class #{klass}\n  undef #{name}\n  def #{name}\n  skip\nend\nend"
    end
  end
end



# Load the test files from the command line.

ARGV.each do |f| 
  next if f =~ /^-/

  if f =~ /\*/
    FileList[f].to_a.each { |fn| load fn }
  else
    load f
  end
end

# Load pending tests
load "spec/remote_rake_tests_marked_pending.rb"
