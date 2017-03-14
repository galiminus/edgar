module Edgar
  class DailyVideoPerformanceWorker
    include ::Sidekiq::Worker

    def perform
      definition = Edgar::ReportDefinition.new('VIDEO PERFORMANCE')
      client = Edgar::AdwordsClient.new Team.find_by_name(ENV['EDGAR_TEAM_NAME'])
      client.connect

      selector = {
        fields: ['CustomerId',  'Name'],
        paging: { start_index: 0, number_results: 10000 }
      }

      accounts = client.service(:accounts).get(selector)

      accounts[:entries].reject{ |e| e[:name] == 'Amuse' }.each do |account|

        data = client.for(account[:customer_id]).report(definition)

        record = Edgar::Report.where('date >= ?', Time.zone.now.beginning_of_day)
        .first_or_create(name: 'Video Performance Report')

        record.date = (Time.zone.now - 1.day).beginning_of_day
        record.account_id = account[:customer_id],
        record.adwords_data_raw = CSV.parse(data).to_json
        record.replenish!
        record.save!

        Edgar::AWSClient.new(
          "daily-video-performance-#{account[:customer_id]}-#{(Time.zone.now - 1.day).strftime('%d%m%Y')}.csv",
          StringIO.new(data)
        ).upload
      end
    end
  end
end
