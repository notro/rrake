
# We need this to be able to use log4r on Windows
# http://www.koders.com/c/fidBEA5080B961B453D266F1A0237E28603D8BEF04A.aspx?s=cdefs.h#L159

module Syslog
  module Constants
    LOG_EMERG = 0
    LOG_ALERT = 1
    LOG_CRIT = 2
    LOG_ERR = 3
    LOG_WARNING = 4
    LOG_NOTICE = 5
    LOG_INFO = 6
    LOG_DEBUG = 7
  end
end