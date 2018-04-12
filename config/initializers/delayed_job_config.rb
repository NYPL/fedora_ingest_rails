require 'nypl_log_formatter'

Delayed::Worker.logger =  NyplLogFormatter.new(STDOUT)

# The default is true
Delayed::Worker.destroy_failed_jobs = false
