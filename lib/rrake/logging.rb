require 'rubygems'

# Windows doesn't have syslog which log4r requires
begin
  require 'syslog'
rescue LoadError
  require 'rrake/windows_syslog'
  $".unshift 'syslog'
#  $".each {|i| puts "  #{i}"}
end

require 'log4r'
require 'log4r/configurator'

RRAKE_LOGCTX = 'log_ctx'


# $stdout = http://stackoverflow.com/questions/1989373/ruby-stdio-consts-and-globals-what-are-the-uses
#           http://stackoverflow.com/questions/3018595/how-do-i-redirect-stderr-and-stdout-to-file-for-a-ruby-script
# string variable = http://stackoverflow.com/questions/1484129/ruby-send-logger-messages-to-a-string-variable
# http://blog.mattwynne.net/2008/10/23/logging-http-error-messages-in-ruby-and-rails/
# http://oldwiki.rubyonrails.org/rails/pages/HowtoConfigureLogging
# How to overwrite standard puts method 
# http://www.ruby-forum.com/topic/226569

module Rake
  
  # Provides logging functionality
  # The including class provides the log method which returns a Log4r::Logger
  module Logging
    def log_init(logger_name)
      current_verbose = $VERBOSE
      $VERBOSE = false
      Log4r::Configurator.custom_levels :DEBUG2, :DEBUG, :INFO, :WARN, :ERROR, :FATAL
      logger = Log4r::Logger.new logger_name
#      log4jformat = Log4r::Log4jXmlFormatter.new
#      stdout = Log4r::StdoutOutputter.new 'log4r'
      #stdout.formatter = log4jformat
#      stdout.formatter = Log4r::PatternFormatter.new :pattern => "%d %5l %m"
#      logger.outputters = [stdout]
      logger.level = Log4r::INFO
      $VERBOSE = current_verbose
      logger
    end
    
    def log_context
      if Thread.current[RRAKE_LOGCTX].nil?
        Thread.current[RRAKE_LOGCTX] = {}
      end
      n = self.respond_to?(:name) ? self.name : ""
      Thread.current[RRAKE_LOGCTX][n].to_s
    end
    
    def log_context=(value)
      log_context
      Thread.current[RRAKE_LOGCTX][self.name] = value.to_s
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
    
    def log_event(level, message, &block)
      log.send level.to_s.downcase, "[#{log_context}] #{message}" if respond_to?(:log) and !log.nil?
    end
  end
  
end