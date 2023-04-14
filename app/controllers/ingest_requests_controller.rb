# frozen_string_literal: true

class IngestRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    uuids = params[:uuids].compact.uniq.map(&:strip)
    test_mode = params[:test_mode] || false
    uuids.each { |uuid| IngestRequest.create(uuid: uuid, test_mode: test_mode) }
    head :created
  end
end
