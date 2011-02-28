#!/usr/bin/env ruby

require 'rrake'


# Remove a test from the test suite
def remove_test(klass, name)
  if Object.const_defined?(klass)
    eval "class #{klass}\n  undef #{name}\nend"
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

# Remove reimplemented tests
load "spec/rake_tests_removed.rb"
