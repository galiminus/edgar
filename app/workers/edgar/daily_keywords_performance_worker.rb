module Edgar
  class DailyKeywordsPerformanceWorker
    include Sidekiq::Worker

    def perform
      definition = Edgar::ReportDefinition.new('KEYWORDS PERFORMANCE')
      client = Edgar::AdwordsClient.new Team.find_by_name(ENV['EDGAR_TEAM_NAME'])
      client.connect

      selector = {
        fields: ['CustomerId',  'Name'],
        paging: { start_index: 0, number_results: 10000 }
      }

      accounts = client.service(:accounts).get(selector)

      accounts[:entries].reject{ |e| e[:name] == 'Amuse' }.each do |account|

        data = client.for(account[:customer_id]).report(definition)

        Edgar::AWSClient.new(
          "daily-video-performance-#{account[:customer_id]}-#{(Time.zone.now - 1.day).strftime('%d%m%Y')}.csv",
          StringIO.new(data)
        ).upload

        ts = CSV.parse(data)[2..-1].map do |row|
          {
            tags: {
              campaign_id: row[0],
              campaign_name: row[1],
              adgroup_id: row[4],
              keyword_id: row[5],
              keyword: row[6],
            },
            values: Hash.new(0).merge!(
              clicks: row[7].to_f
            )
          }
        end

        influxdb = Edgar::InfluxDBClient.new
        influxdb.write(ts, 'daily_keywords_performance')
      end
    end
  end
end
