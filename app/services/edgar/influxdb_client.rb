module Edgar

  # Provides a lightweight wrapper for influxDB.
  #
  #   client = Edgar::InfuxDBClient.new
  #
  #   data = [
  #     {
  #       series: 'cpu',
  #       tags:   { host: 'server_1', region: 'us' },
  #       values: { internal: 5, external: 0.453345 }
  #     },
  #     {
  #       series: 'gpu',
  #       values: { value: 0.9999 },
  #     }
  #   ]
  #
  #   client.write(data)
  #
  class InfluxDBClient
    def initialize
      @client = InfluxDB::Client.new 'edgar'
    end

    def write(data, name=nil)
      if data.is_a? Array
        @client.write_points(data, 'm')
      elsif data.is_a? Hash
        raise 'You must name your series!' if name.nil?
        @client.write_point(name, data, 's')
      else
        raise 'Your data must be a Hash or an Array!'
      end
    end
  end
end
