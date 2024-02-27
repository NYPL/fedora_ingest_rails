# frozen_string_literal: true

class SingleFieldUpdatesController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  require 'rsolr'
  require 'json'

  def update_fields    
    # Check if any of the required parameters are missing
    validity_bool, message = validate_json_and_format(params[:single_field_updates])
    if validity_bool == false
      render json: { error: message }, status: :bad_request
    else 
      # Parse the requested updates into batches of 300 and queue in delayed jobs for updating solr.
      # example single_field_updates = [{"uuid":"uuid-uuid-uuid-uuid","field_name":"vrr_requestable","field_value":"true"}]
      single_field_update_batches = params[:single_field_updates].each_slice(300).to_a
      single_field_update_batches.each do |single_batch_array|
        RepoSolrClient.new.delay(queue: 'update_fields').update_solr_documents(single_batch_array)  
      end
    
      head :ok
    end
  end
  
  private

  def validate_json_and_format(updates_array)
    # Check if the input is valid JSON
    begin
      json_string = updates_array.to_json
      JSON.parse(json_string)
    rescue JSON::ParserError
      return false, 'Invalid JSON'
    end
    
    # Validate and return error messages for invalid updates array values. 
    validate_updates_array(updates_array)
  end
  
  def validate_updates_array(updates_array)
    unless updates_array.is_a?(Array)
      return false, "Invalid body format for method."
    end
    
    updates_array.each do |entry|
      unless valid_entry?(entry)
        return false, 'Invalid entry format in "single_field_values"'
      end
    end
    
    # If all checks pass, the hash is valid
    return true, 'Valid JSON and format'
  end

  def valid_entry?(entry)
    # transform keys if necessary; sometimes the keys are symbols and sometimes not. 
    entry = entry.transform_keys(&:to_sym) if entry.is_a?(Hash)
    
    entry.key?(:uuid) && entry.key?(:field_name) && entry.key?(:field_value)
  rescue StandardError
    false
  end
  
end