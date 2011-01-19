# This example achieves the same as: rrake --log stdout:debug --server -s webrick -E test
# Options passed to this script is parsed as with rackup
# server.rb -h gives the options

require 'rrake'


# Setup rrake logging stdout:debug
Rake.application.log.level = Log4r::DEBUG
outp = Log4r::StdoutOutputter.new 'stdout'
outp.formatter = Log4r::PatternFormatter.new :pattern => "%d %6l %m"
Rake.application.log.outputters << outp

srv = Rack::Server.new

# The parsing of command line options is done when options is used for the first time
srv.options

# -E
# default: development
srv.options[:environment] = 'test' unless srv.options[:environment]

# -s
# default: mongrel is used if installed, if not webrick is used.
srv.options[:server] = 'webrick' unless srv.options[:server]

# -p
# default: 9292
srv.options[:Port] = 9292 unless srv.options[:Port]

# This configures the WEBrick logger which by default logs to $stderr
srv.options[:Logger] = Rake.application.log if srv.server == Rack::Handler::WEBrick

puts "\nRack options:";
srv.options.each { |k,v| puts "  #{k} => #{v}" }
print "\n"

# Register a middelware environment that can be chosen with the -E switch
srv.middleware.merge!( 'test' => [lambda {|server| server.server.name =~ /CGI/ ? nil : [Rack::LoggingLogger, Rake.application.log] }] )

puts "Registered middleware:";
srv.middleware.each { |k,v| print "  #{k} => "; p v }
print "\n"

print "Server: "; p srv.server
print "\n----------\n"


srv.app = Rake::API
srv.start
