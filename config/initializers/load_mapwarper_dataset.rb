# frozen_string_literal: true

# Preload the Mapwarper dataset into memory on application start.
# This file is large (~17MB), so we load it once and keep it in memory.
Rails.application.config.after_initialize do
  MapwarperDataset.data
end
