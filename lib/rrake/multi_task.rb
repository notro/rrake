module Rake

  # Same as a regular task, but the immediate prerequisites are done in
  # parallel using Ruby threads.
  #
  class MultiTask < Task
    private
    def invoke_prerequisites(args, invocation_chain)
      threads = @prerequisites.collect { |p|
        thread = Thread.new(p, Rake.get_session) { |r, s| Rake.set_session s; application[r, @scope].invoke_with_call_chain(args, invocation_chain) }
        thread
      }
      threads.each { |t| t.join }
    end
  end

end
