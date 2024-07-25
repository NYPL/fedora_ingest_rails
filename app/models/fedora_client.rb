# frozen_string_literal: true

require 'rubydora'

class FedoraClient
  attr_reader :repository

  def initialize
    @repository = Rubydora.connect(
      url: Rails.application.credentials.fedora_url,
      user: Rails.application.credentials.fedora_username,
      password: Rails.application.credentials.fedora_password
    )
  end
end
