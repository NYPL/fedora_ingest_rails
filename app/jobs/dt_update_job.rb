class DtUpdateJob
  def initialize(page, per_page)
    @page = page
    @per_page = per_page
  end

  def perform
    # Call your method with the provided arguments
    batch_dt_update(@page, @per_page)
  end

  def batch_dt_update(page, per_page)
    ActiveRecord::Base.logger.level = 2

    solr_url = 'http://10.225.132.218:8983/solr/repoapi'
    solr = RSolr.connect(url: solr_url)

    solr_params = { :q => '*:*', :fl =>'uuid,dateIndexed_s,firstIndexed_s', sort: 'firstIndexed_s asc' }
    response = solr.paginate(page, per_page, 'select', :params => solr_params)
    update_data = []

    docs = response['response']['docs']
    docs.each do |doc|
      uuid = doc['uuid']
      date_indexed_dt = doc['dateIndexed_s']&.first
      first_indexed_dt = doc['firstIndexed_s']&.first
      next unless date_indexed_dt
      update = {}
      update[:uuid] = uuid
      update[:dateIndexed_dt] = { set: date_indexed_dt } unless date_indexed_dt.blank?
      update[:firstIndexed_dt] = { set: first_indexed_dt } unless first_indexed_dt.blank?
      update_data << update unless update == { uuid: uuid }
    end

    begin
      update_params = { params: { commit: true }, data: update_data.to_json }
      response = solr.update(update_params)
    rescue StandardError => e
      puts "Got a hiccup. Going one by one."
      update_data.each do |datum|
        update_params = { params: { commit: true }, data: [datum].to_json }
        begin
          response = solr.update(update_params)
        rescue StandardError => e
          datum[:firstIndexed_dt] = { set: DateTime.parse(datum[:firstIndexed_dt][:set].to_s).utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          datum[:dateIndexed_dt] = { set: DateTime.parse(datum[:dateIndexed_dt][:set].to_s).utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          update_params = { params: { commit: true }, data: [datum].to_json }
          response = solr.update(update_params)
        end
      end
    end

    puts "at page: #{page} of 3791"
  end
end
