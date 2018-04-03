class IngestHistoryController < ApplicationController
  # An API endpoint of any UUID's (paginated) histroy
  def show
    @ingest_requests = IngestRequest.where(uuid: params[:id]).order('created_at DESC').paginate(page: params[:page], per_page: 500)
    render json: @ingest_requests
  end
end
