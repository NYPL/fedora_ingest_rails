# frozen_string_literal: true

require 'rubydora'

class FedoraClient
  attr_reader :repository

  def initialize
    @repository = Rubydora.connect(
      url: Rails.application.secrets.fedora_url,
      user: Rails.application.secrets.fedora_username,
      password: Rails.application.secrets.fedora_password
    )
  end
end
