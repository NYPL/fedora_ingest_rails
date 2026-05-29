# frozen_string_literal: true

class MapwarperDataset
  def self.data
    @data ||= load_data
  end

  def self.uuids
    @uuids ||= begin
      return Set.new unless data
      uuids = data['features'].map { |f| f.dig('properties', 'data', 'uuid') }.compact
      Set.new(uuids)
    end
  end

  def self.has_uuid?(uuid)
    uuids.include?(uuid)
  end

  def self.load_data
    path = Rails.root.join('lib', 'data', 'mapwarper.geojson')
    if File.exist?(path)
      JSON.parse(File.read(path))
    else
      Rails.logger.warn("Mapwarper dataset not found at #{path}")
      nil
    end
  end
end
