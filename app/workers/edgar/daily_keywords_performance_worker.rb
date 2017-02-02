module Edgar
  class DailyKeywordsPerformanceWorker
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { daily }

    def perform
      definition = Edgar::ReportDefinition.new('KEYWORDS PERFORMANCE')
      client = Edgar::AdwordsClient.new Team.find_by_name(ENV['EDGAR_TEAM_NAME'])
      client.connect

      selector = {
        fields: ['CustomerId',  'Name'],
        paging: { start_index: 0, number_results: 10000 }
      }

      accounts = client.service(:accounts).get(selector)

      accounts[:entries].drop(1).each do |account|

        data = client.for(account[:customer_id]).report(definition)

        Edgar::AWSClient.new(
          "daily-video-performance-#{account[:customer_id]}-#{Time.zone.now.strftime('%d%m%Y')}.csv",
          StringIO.new(data)
        ).upload

        ts = CSV.parse(data)[2..-1].map do |row|
          {
            series: account[:customer_id],
            tags: [
              row[0], # CampaignId
              row[1], # Campaign
              row[4], # AdGroupId
              row[5], # KeywordId
              row[6], # Keyword
              'daily', 'video', 'performance', 'youtube', 'adwords', 'kpi'
            ],
            values: Hash.new(0).merge!(
              clicks: row[7]
            )
          }
        end

        influxdb = Edgar::InfluxDBClient.new
        influx.write(ts, 'daily_keywords_performance')
      end
    end
  end
end
