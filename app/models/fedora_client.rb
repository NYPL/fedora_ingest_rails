# frozen_string_literal: true

require 'rubydora'

class FedoraClient
  attr_reader :repository

  def initialize
    @repository = Rubydora.connect(
      url: Rails.application.config.fedora_url,
      user: Rails.application.config.fedora_username,
      password: Rails.application.config.fedora_password
    )
  end
end
