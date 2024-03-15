# app/controllers/delayed_jobs_controller.rb

class DelayedJobsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :forbidden_action

  def forbidden_action
    redirect_to delayed_job_path, alert: 'You are not authorized to perform this action.'
  end
end

