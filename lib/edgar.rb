require 'edgar/engine'
require 'adwords_api'
require 'influxdb'
require 'sidekiq'
require 'csv'

module Edgar
  def self.load_paths
    [
      'app/services/edgar/',
      'app/workers/edgar/'
    ]
  end
end
