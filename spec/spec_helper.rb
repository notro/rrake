$LOAD_PATH << '.'

# Make sure rake or test/unit is not loaded in the unit tests
module ::Kernel
  alias :helper_orig_require :require
  def require(file)
    return true if file =~ /^test\/unit|^rake/
    helper_orig_require(file)
  end 
end


require 'rrake'
require 'spec/testserver.rb'
require 'test/capture_stdout'
require 'test/in_environment'
require 'rspec/unit'


module Test
  module Unit
    TestCase = RSpec::Unit::TestCase
    Assertions = RSpec::Unit::Assertions
  end
end


class RSpec::Unit::TestCase
  include ::Rake::DSL
end


class RSpec::Core::ExampleGroup
  include ::Rake::DSL
  
  def name
    example.metadata[:description]
  end
end


module CommandHelp
  def command_line(*options)
    options.each do |opt| ARGV << opt end
    @app = Rake::Application.new
    def @app.exit(*args)
      throw :system_exit, :exit
    end
    @app.instance_eval do
      handle_options
      collect_tasks
    end
    @tasks = @app.top_level_tasks
    @app.options
  end
end



Rake.application.options.port = Rake::Application::DEFAULT_PORT

# Run all tests
::RSpec.world.runs << []

# Run test unit test as remote tasks excluding tests in rake_tests_removed.rb
::RSpec.world.runs << [
  {:test_unit => true}, 
  {:not_remote => true}, 
  lambda {
    puts "\nRAKE_REMOTE = http://127.0.0.1:9292" if ENV['VERBOSE']
    TestServer.start 
    ENV['RAKE_REMOTE'] = "http://127.0.0.1:9292"
  },
  lambda {
    ENV['RAKE_REMOTE'] = nil
  }
]


::RSpec.configure do |config|
  
  config.before(:suite) do
    def add_meta(item, key, value)
      item.metadata[key] = value
      item.metadata[:example_group][key] = value if item.metadata[:example_group]
      item.examples.each { |example| example.metadata[key] = value; example.metadata[:example_group][key] = value if example.metadata[:example_group] }
      item.children { |child| add_meta child, key, value }
    end
    
    def add_meta_if_example(group, key, group_desc, example_desc)
      group.children.each { |g| add_meta_if_example g, key, group_desc, example_desc }
      if group.metadata[:example_group][:description].to_s == group_desc.to_s
        group.examples.each { |example|
          if example.metadata[:description].to_s == example_desc.to_s
            example.metadata[key] = true
            example.metadata[:example_group][key] = true
          end
        }
      end
    end
    
    @not_remote = []
    def test_reimplemented(klass, test)
      @not_remote << [klass, test]
    end
    
    def test_not_reimplemented(klass, test)
      @not_remote << [klass, test]
    end
    
    load "./spec/rake_tests_removed.rb"
    
    RSpec.world.example_groups.each { |group|
      @not_remote.each { |klass, test|
        add_meta_if_example group, :not_remote, klass, test
      }
      add_meta(group, :not_remote, true) if group.metadata[:example_group][:caller][0].include? "test/lib/rules_test.rb"
    }
  end
  
  config.after(:suite) do
    TestServer.shutdown
  end
  
end

