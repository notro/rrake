require 'rrake/application'
require 'rrake/session'

module Rake

  DEFAULT_SESSION = 'DEFAULT'

  @sessions = {}
  @threads = {}
  
  # Rake module singleton methods.
  #
  class << self
    # Current Rake Application
    def application
      if self.get_session.nil?
        self.application = nil unless @sessions[DEFAULT_SESSION]
        self.set_session DEFAULT_SESSION
      end
      expire_sessions
      @sessions[self.get_session].last_access = Time.now
      @sessions[self.get_session].app
    end

    # Set the current Rake application object.
    def application=(app)
      self.new_session(DEFAULT_SESSION, nil, app)
      self.set_session DEFAULT_SESSION
    end

    # Return the original directory where the Rake application was started.
    def original_dir
      application.original_dir
    end

    # Hash of sessions: id => Session object
    def sessions
      @sessions
    end

    # Hash of session threads: thread => session id
    def session_threads # :nodoc:
      @threads
    end

    # Create new session.
    def new_session(session_id=nil, timeout=Rake::Session::DEFAULT_TIMEOUT, app=nil)
      session_id ||= rand(32**10).to_s(32)
      raise "session id already in use: '#{session_id}'" if (session_id != DEFAULT_SESSION) && (@sessions.include? session_id)
      app ||= Rake::Application.new
      @sessions[session_id] = Rake::Session.new(app, timeout)
      session_id
    end

    # Returns session id for the thread. nil if not set.
    def get_session(thread=Thread.current)
      @threads[thread.to_s]
    end

    # Set session id for the thread
    def set_session(session_id, thread=Thread.current)
      raise "no such session: '#{session_id}'" unless @sessions.include? session_id
      @threads[thread.to_s] = session_id
    end

    # Removes all sessions
    def clear_sessions(default_session_also=false)
      default = @sessions[DEFAULT_SESSION]
      default = nil if default_session_also
      @sessions = {}
      @sessions[DEFAULT_SESSION] = default if default
      @threads = {}
    end

    # Expire session if timeout is reached and no thread is using the session
    def expire_sessions # :nodoc:
      thread_list = Thread.list.collect { |thread| thread.to_s }
      @threads.reject! { |thread, sessionid| !thread_list.include?(thread) }
      @sessions.reject! { |id, session| session.timeout && Time.now > session.last_access + session.timeout && !@threads.values.include?(session) }
    end

  end

end
