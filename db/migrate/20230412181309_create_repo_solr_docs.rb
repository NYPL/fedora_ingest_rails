class CreateRepoSolrDocs < ActiveRecord::Migration[5.2]
  def up
    create_table :repo_solr_docs do |t|
      t.string :uuid, limit: 36
      t.timestamp :first_indexed
    end
    add_index :repo_solr_docs, :uuid, unique: true
  end

  def down
    drop_table :repo_solr_docs
  end
end
