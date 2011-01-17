require 'rubygems'

# Windows doesn't have syslog which log4r requires
begin
  require 'syslog'
rescue LoadError
  require 'rrake/windows_syslog'
  $".unshift 'syslog'
end

require 'log4r'
require 'log4r/configurator'


module Rake
  
  # Thread variable to hold the context for log entries
  RRAKE_LOGCTX = 'log_ctx'
  
  # Provides logging functionality
  # The including class provides the log method which returns a Log4r::Logger
  module Logging
  
    # Initialize Log4r with custom log levels and return the logger
    def log_init(logger_name) # :nodoc:
      current_verbose = $VERBOSE
      $VERBOSE = false
      Log4r::Configurator.custom_levels :DEBUG2, :DEBUG, :INFO, :WARN, :ERROR, :FATAL
      logger = Log4r::Logger.new logger_name
      logger.level = Log4r::OFF
      $VERBOSE = current_verbose
      logger
    end
    
    # Add log outputter with right format, and adjust logger level.
    def log_add_output(out, level) # :nodoc:
      out.formatter = Log4r::PatternFormatter.new :pattern => "%d %6l %m"
      out.level = level
      if log.level > level
        current_verbose = $VERBOSE
        $VERBOSE = false
        log.level = level
        $VERBOSE = current_verbose
      end
      log.add out
    end
    
    # Get the logging context for the Application or Task instances. Shows up in log output between brackets.
    def log_context
      if Thread.current[RRAKE_LOGCTX].nil?
        Thread.current[RRAKE_LOGCTX] = {}
      end
      n = self.respond_to?(:name) ? self.name : "<no name>"
      Thread.current[RRAKE_LOGCTX][n].to_s
    end
    
    # Set the logging context.
    def log_context=(value)
      log_context
      n = self.respond_to?(:name) ? self.name : "<no name>"
      Thread.current[RRAKE_LOGCTX][n] = value.to_s
    end
    
    def debug2(message, &block)
      log_event :DEBUG2, message, &block
    end
    
    def debug(message, &block)
      log_event :DEBUG, message, &block
    end
    
    def info(message, &block)
      log_event :INFO, message, &block
    end
    
    def warn(message, &block)
      log_event :WARN, message, &block
    end
    
    def error(message, &block)
      log_event :ERROR, message, &block
    end
    
    def fatal(message, &block)
      log_event :FATAL, message, &block
    end
    
    def log_event(level, message, &block) # :nodoc:
      log.send level.to_s.downcase, "[#{log_context}] #{message}" if respond_to?(:log) and !log.nil?
    end
  end
  
end