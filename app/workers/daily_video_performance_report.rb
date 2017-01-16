class DailyVideoPerformanceWorker
  include ::Sidekiq::Worker
  include ::Sidetiq::Schedulable

  recurrence { daily }

  def perform
    definition = Edgar::ReportDefinition.new('VIDEO PERFORMANCE')
    client = Edgar::AdwordsClient.new Team.find(3)
    client.connect

    selector = { :fields => ['CustomerId',  'Name'], :paging => { start_index: 0, number_results: 1000 } }
    accounts = client.service(:accounts).get(selector)

    accounts[:entries].drop(1).each_with_index do |account, index|

      data = client.for(account[:customer_id]).report(definition)

      Edgar::AWSClient.new(
        "daily-video-performance-#{account[:customer_id]}-#{Time.current.to_s}.csv",
        StringIO.new(data)
      ).upload
      
      data = CSV.parse(data)

      ts = {
        tags: ['video', 'performance', 'youtube', 'kpi'],
        values: data[1].tap{ |e| e.delete_at(0) }
        .map{ |e| e.downcase.gsub(' ', '_').gsub('.', '').to_sym }
          .zip(
            data[-1].tap{ |e| e.delete_at(0) }
          .map(&:to_f)
        ).to_h,
      }

      influxdb = Edgar::InfluxDBClient.new
      influxdb.write(ts, "daily_video_performance_#{account[:customer_id]}")

    end
  end
end
