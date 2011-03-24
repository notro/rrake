require 'nestful'

module Nestful
  # Nestful::Request#uri insist on adding an extension to the url.
  # 
  # This code removes that functionality.
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


# This is the only place in nestful that extension is used as of dec. 2010.
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

