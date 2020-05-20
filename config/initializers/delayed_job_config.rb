# frozen_string_literal: true

require 'nypl_log_formatter'

Delayed::Worker.logger = NyplLogFormatter.new(STDOUT)
