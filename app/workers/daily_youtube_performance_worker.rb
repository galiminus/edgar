module Edgar
  class DailyYoutubePerformanceWorker
    include ::Sidekiq::Worker
    include ::Sidetiq::Schedulable

    recurrence { daily }

    def perform
      client = Edgar::YoutubeAnalyticsClient.new.core

      data = client.channels.map do |channel|
        {
          id: channel.id,
          title: channel.title,
          date: Time.zone.now,
          views: channel.views(
            by: :day,
            since: 1.day.ago,
            until: 1.day.ago
          ),
          monetized_playbacks: channel.monetized_playbacks,
          revenue: channel.estimated_revenue(
            since: 1.day.ago,
            until: 1.day.ago,
            in: 'FR'
          ),
          subscribers: channel.subscriber_count
        }
      end

      record = Edgar::Report.where('date >= ?', Time.zone.now.beginning_of_day)
      .first_or_create(name: 'Video Peqrformance Report')

      record.youtube_data_raw = data.to_json
      record.save!

      stringIO = StringIO.new
      stringIO << data.keys.join(',') << '\r\n'
      data.values.each_slice(data.keys.count) do |line|
        stringIO << line.join(',') << '\r\n'
      end

      Edgar::AWSClient.new(
        "daily-youtube-performance-#{client.id}-#{Time.zone.now.strftime('%d%m%Y')}.csv",
        stringIO
      ).upload
    end
  end
end
