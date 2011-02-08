require 'rrake/ext/nestful'


module Rake
  # This module depends on two methods in the including class:
  # * url - The base url which is joined with rel_url
  # * log_context - Used to pass on logging info to the server
  module RestClient
    # GET request
    #   self.url = "http://server.com/api/v1"
    #   self.log_context "task0 => task1"
    #   rget "tasks/task1/needed"   # actual request => "http://server.com/api/v1/tasks/task1/needed?trace=task0+%3D%3E+task1"
    def rget(rel_url, params = {})
      rrequest :get, rel_url, params
    end
    
    # POST request
    #   self.url = "http://server.com/api/v1"
    #   rpost "tasks/task1", {:klass => Rake::Task}
    def rpost(rel_url, params = {})
      rrequest :post, rel_url, params
    end
  
    # PUT request
    #   self.url = "http://server.com/api/v1"
    #   rput "tasks/task1/execute"
    def rput(rel_url, params = {})
      rrequest :put, rel_url, params
    end
  
#--
#    def rdelete(rel_url, params = {})
#      rrequest :delete, rel_url, params
#    end
#++
  
    def rrequest(method, rel_url, params = {})
      params.merge! :trace => self.log_context
      begin
        Nestful::Request.new("#{File.join(self.url, rel_url)}", {:method => method, :format => :json, :params => params}).execute
      rescue Exception => e
        error "'#{File.join(self.url, rel_url)}' #{e.inspect}" if self.respond_to? :error
        raise
      end
    end
  end
end