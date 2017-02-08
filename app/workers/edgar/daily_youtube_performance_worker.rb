module Edgar
  class DailyYoutubePerformanceWorker
    include ::Sidekiq::Worker
    include ::Sidetiq::Schedulable

    recurrence { daily }

    def perform
      client = Edgar::YoutubeAnalyticsClient.new
      channels = YoutubeChannel.for(Team.find_by_name(ENV['EDGAR_TEAM_NAME']))

      data = channels.map(&:id).map do |id|
        channel = client.for(id)

        {
          id: channel.id,
          title: channel.title,
          date: Time.zone.now,
          views: channel.views(
            by: :day,
            since: 1.day.ago,
            until: 1.day.ago
          ).values.reduce(:+),
          monetized_playbacks: channel.monetized_playbacks[:total],
          revenue: channel.estimated_revenue(
            since: 1.day.ago,
            until: 1.day.ago,
            in: 'FR'
          ).values.reduce(:+),
          subscribers: channel.subscriber_count
        }
      end

      record = Edgar::Report.where('date >= ?', (Time.zone.now - 1.day).beginning_of_day)
      .first_or_create(name: 'Video Performance Report')

      record.date ||= (Time.zone.now - 1.day).beginning_of_day
      record.youtube_data_raw = data.to_json
      record.save!

      stringIO = StringIO.new
      stringIO << data.first.keys.join(',') << '\r\n'

      data.each do |dataset|
        dataset.values.each_slice(dataset.keys.count) do |row|
          stringIO << row.join(',') << '\r\n'
        end
      end

      Edgar::AWSClient.new(
        "daily-youtube-performance-#{(Time.zone.now - 1.day).strftime('%d%m%Y')}.csv",
        stringIO
      ).upload
    end
  end
end
