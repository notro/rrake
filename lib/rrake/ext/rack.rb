require 'rack'

module Rack
  class Server
    rake_extension("app=") do
      def app=(app)
        @app = app
      end
    end
  end

  class LoggingLogger < CommonLogger
    FORMAT = %{%s - %s "%s %s%s %s" %d %s %0.4f}

    def initialize(app, logger)
      @app = app
      @logger = logger
    end

    def log(env, status, header, began_at)
      now = Time.now
      length = extract_content_length(header)

      msg = FORMAT % [
        env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
        env["REMOTE_USER"] || "-",
        env["REQUEST_METHOD"],
        env["PATH_INFO"],
        env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
        env["HTTP_VERSION"],
        status.to_s[0..3],
        length,
        now - began_at ]
      
      @logger.debug msg
    end
  end
end
