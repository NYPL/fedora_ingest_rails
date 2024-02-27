# frozen_string_literal: true

class RepoSolrDoc < ApplicationRecord
  validates_presence_of :uuid
  
  def self.get_datetime_s
    self.format_as_solr_s(Time.current)
  end
  
  def self.get_datetime_dt
    self.format_as_solr_dt(Time.current)
  end
  
  def self.format_as_solr_s(datetime)
    datetime.iso8601(3)
  end
  
  def self.format_as_solr_dt(datetime)
    datetime.strftime('%Y-%m-%dT%H:%M:%SZ')
  end
end
