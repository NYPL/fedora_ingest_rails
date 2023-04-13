# frozen_string_literal: true

class RepoSolrDoc < ApplicationRecord
  validates_presence_of :uuid
end
