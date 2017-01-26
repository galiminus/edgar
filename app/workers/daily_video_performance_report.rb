class DailyVideoPerformanceWorker
  include ::Sidekiq::Worker
  include ::Sidetiq::Schedulable

  recurrence { daily }

  def perform
    definition = Edgar::ReportDefinition.new('VIDEO PERFORMANCE')
    client = Edgar::AdwordsClient.new Team.find(3)
    client.connect

    selector = {
      fields: ['CustomerId',  'Name'],
      paging: { start_index: 0, number_results: 10000 }
    }

    accounts = client.service(:accounts).get(selector)

    accounts[:entries].drop(1).each do |account|

      data = client.for(account[:customer_id]).report(definition)

      record = Edgar::Report.where('date >= ?', Time.zone.now.beginning_of_day)
      .first_or_create(name: 'Video Performance Report')

      record.account_name = account[:name],
      record.account_id = account[:customer_id],
      record.adwords_data_raw = CSV.parse(data).to_json
      record.save!
 
      Edgar::AWSClient.new(
        "daily-video-performance-#{account[:customer_id]}-#{Time.zone.now.strftime('%d%m%Y')}.csv",
        StringIO.new(data)
      ).upload
    end
  end
end
