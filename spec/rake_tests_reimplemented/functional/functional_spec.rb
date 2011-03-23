#!/usr/bin/env ruby

begin
  require 'rubygems'
  gem 'session'
  puts "RUNNING WITH SESSIONS" if require 'session'
rescue LoadError
  puts "UNABLE TO RUN FUNCTIONAL TESTS"
  puts "No Session Found (gem install session)"
end

require 'spec/rake_tests_reimplemented/functional/session_based_specs.rb' if defined?(Session)
