module Edgar
  class InfluxDBClient
    def initialize
      @client = InfluxDB::Client.new 'edgar'
    end

    def write(data)
      @client.write_points(data, 'm')
    end
  end
end
