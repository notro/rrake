
module Rake

  class Session
    DEFAULT_TIMEOUT = 600
    
    # Application object for this session
    attr_reader :app

    # Last time this application was accessed through Rake.application
    attr_accessor :last_access

    # Timeout for this session to expire after last access
    attr_reader :timeout

    # app: Application object for this session. If timeout=nil, never expire.
    def initialize(app, timeout=DEFAULT_TIMEOUT)
      @app = app
      @timeout = timeout
      @last_access = Time.now
    end

  end

end