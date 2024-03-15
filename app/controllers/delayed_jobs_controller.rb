# app/controllers/delayed_jobs_controller.rb

class DelayedJobsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :forbidden_action

  def forbidden_action
    # Respond with 403 Forbidden status
    head :forbidden
  end
end

