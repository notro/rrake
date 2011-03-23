require 'rubygems'
require 'rspec/core'


module RSpec
  module Core
    class World
      # An array of arrays defining multiple runs within one rspec report
      # One run consists of: include_filter, exclude_filter, before_block, after_block
      #
      # Example:
      #   # Run all tests
      #   RSpec.world.runs << []
      #   # Run the slow tests once more with environment variable set
      #   RSpec.world.runs << [{:slow => true}, nil, lambda { puts "Starting run two"; ENV['SLOW'] = 1 }, lambda { puts "Ending run two" } ]
      #
      attr_accessor :runs
      
      def runs #:nodoc
        @runs ||= []
      end
    end
    
    class CommandLine
      def run(err, out)
        @configuration.error_stream = err
        @configuration.output_stream ||= out
        @options.configure(@configuration)
        @configuration.load_spec_files
        @configuration.configure_mock_framework
        @configuration.configure_expectation_framework
#        @world.announce_inclusion_filter
#        @world.announce_exclusion_filter
        @configuration.run_hook(:before, :suite)                                          #

        @configuration.reporter.report(@world.example_count) do |reporter|
          begin
#            @configuration.run_hook(:before, :suite)
            @world.runs.each { |include_filter, exclude_filter, before, after|            #
              @world.filtered_examples.clear                                               #
              @configuration.filter_run_including(include_filter, true) if include_filter  #
              @configuration.filter_run_excluding(exclude_filter) if exclude_filter        #
              before.call if before and @world.example_count > 0                           #
              @world.example_groups.map {|g| g.run(reporter)}.all?
              after.call if after and @world.example_count > 0                             #
            }                                                                              #
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end
  end
end


RSpec::Core::Runner.autorun
