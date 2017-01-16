require 'edgar/engine'
require 'adwords_api'
require 'influxdb'
require 'sidekiq'
require 'sidetiq'
require 'csv'

module Edgar
  def self.load_paths
    [
      'app/services',
      'app/workers'
    ]
  end
end