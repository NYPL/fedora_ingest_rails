class IngestRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    uuids = params[:uuids].compact.uniq.map(&:strip)
    uuids.each {|uuid| IngestRequest.create(uuid: uuid) }
    head :created
  end
end
