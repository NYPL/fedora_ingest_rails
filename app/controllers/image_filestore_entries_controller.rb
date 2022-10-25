class ImageFilestoreEntriesController < ApplicationController
  
  def status
    if params[:file_id] && ImageFilestoreEntry.has_file?(params[:file_id])
      render json: "Captured"
    else
      render json: "Not found", status: 404
    end
  end
  
end