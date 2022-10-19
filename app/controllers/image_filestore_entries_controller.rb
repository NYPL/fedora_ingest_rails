class ImageFilestoreEntriesController < ApplicationController
  
  def status
    if params[:file_id] && ImageFilestoreEntry.where(file_id: params[:file_id]).present?
      render json: "Captured"
    else
      render json: "Not found", status: 404
    end
  end
  
end