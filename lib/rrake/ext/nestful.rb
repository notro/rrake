require 'nestful'

module Nestful
  class Request
    def uri
      http_url = url.match(/^http/) ? url : "http://#{url}"
      uri      = URI.parse(http_url)
      uri.path = "/" if uri.path.empty?
      #if format && format.extension && !uri.path.match(/\..+/)
      #  uri.path += ".#{format.extension}" 
      #end      
      uri
    end
  end
end


# Nestful::Request.uri insist on adding an extension to the url
# That is the only place in nestful extension is used as of dec. 2010.
#module Nestful
#  module Formats
#    class JsonFormat < Format
#      def extension
#        #"json"
#        nil
#      end
#    end
#  end
#end

