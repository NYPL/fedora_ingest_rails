namespace :urls do
  task migrate: :environment do
    links = 0
    start_time = Time.now

    LinkStore.where("url LIKE ?", "%/fedora/%").find_each(batch_size: 1) do |ls|
      links += 1
      if (links % 1000) == 0
        elapsed_time = Time.now - start_time
        hh, remainder = elapsed_time.divmod(3600)
        mm, ss = remainder.divmod(60)
        formatted_time = "#{hh.to_i.to_s.rjust(2, '0')}:#{mm.to_i.to_s.rjust(2, '0')}:#{ss.to_i.to_s.rjust(2, '0')}"
        puts "Links: #{links} | Total time: #{formatted_time}"
      end

      url = ls.url
      next if url.nil?
      image_id = Capture.find_by(uuid: ls.uuid)&.identifiers&.where(identifier_type: 'image_id')&.limit(1)&.pluck(:identifier_value)&.first
      next if image_id.nil?
      new_url = "https://iiif.nypl.org/index.php?id=#{image_id}&t=u"
      ls.update(url: new_url)
    end
  end
end
