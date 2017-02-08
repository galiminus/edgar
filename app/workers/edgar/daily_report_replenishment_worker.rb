module Edgar
  class DailyReportReplenishmentWorker
    include Sidekiq::Worker

    def perform(id)
      report = Edgar::Report.find(id)

      adwords = report.adwords_data.with_indifferent_access
      youtube = report.youtube_data
      youtube_earned = report.youtube_earned_data

      mxn2usd = JSON.parse(
        Faraday.get('https://api.fixer.io/latest?base=MXN').body
      )['rates']['USD'].to_f

      ts = adwords[:rows].map do |ads|

        yte = youtube_earned.select{ |row| row[:campaign] == ads[:campaign] }.last.with_indifferent_access
        yt = youtube.map{ |e| e.with_indifferent_access }.select{ |row| row[:id] == ads[:video_channel_id] }.last

        views = yt[:views].to_f
        cpv_currency = ads[:views].to_f / ads[:cost].to_f
        earned_paid_views_ratio = yte[:earned_views].to_f / ads[:views].to_f
        playbacks_percentage = yt[:monetized_playbacks].to_f / views
        playbacks = yte[:earned_views].to_f * playbacks_percentage
        real_cpv = (ads[:cost].to_f * mxn2usd) / (ads[:views].to_f + yte[:earned_views].to_f)
        real_cpm = yt[:monetized_playbacks].to_f / yt[:revenue].to_f
        estimated_earnings = yt[:monetized_playbacks].to_f / real_cpm
        roi = (estimated_earnings - ads[:cost].to_f) / ads[:cost].to_f
        profit = estimated_earnings - (ads[:cost].to_f * mxn2usd)
        cost_subscribers = yte[:earned_subscribers].to_f / (ads[:cost].to_f * mxn2usd)
        subscribers_percentage = yte[:earned_subscribers].to_f / yt[:subescribers].to_f

        {
          tags: {
            time: report[:date].strftime('%d%m%Y'),
            campaign_name: ads[:campaign],
            campaign_id: ads[:campaign_id],
            channel_id: ads[:video_channel_id]
          },
          values: Hash.new(0).merge!(
            exchange_rate: mxn2usd,
            #date: ads[:day].to_f,
            views: views.to_f,
            impressions: ads[:impressions].to_f,
            paid_views: ads[:views].to_f,
            view_rate: ads[:view_rate].to_f,
            cost_paid_mxn: ads[:cost].to_f,
            cost: ads[:cost].to_f,
            cpv_currency: cpv_currency.to_f,
            cpv_verification: ads[:average_cpv].to_f,
            earned_views: yte[:earned_views].to_f,
            earned_paid_views_ratio: earned_paid_views_ratio.to_f,
            playbacks_percentage: playbacks_percentage.to_f,
            estimated_playbacks: yt[:monetized_playbacks].to_f,
            playbacks: playbacks.to_f,
            total_earnings: yt[:revenue].to_f,
            real_cpv: real_cpv.to_f,
            real_cpm: real_cpm.to_f,
            estimated_earnings: estimated_earnings.to_f,
            roi: roi.to_f,
            profit: profit.to_f,
            total_subscribers: yt[:subscribers].to_f,
            earned_subscribers: yte[:earned_subscribers].to_f,
            cost_subscribers: cost_subscribers.to_f,
            subscribers_percentage: subscribers_percentage.to_f,
            earned_shares: yte[:earned_shares].to_f,
            earned_playlist: yte[:earned_playlist_additions].to_f
          )
        }
      end

      report.body = ts.to_json
      report.save!

      influxdb = Edgar::InfluxDBClient.new
      influxdb.write(ts, "daily_video_performance")

      report.finalize!
    end
  end
end
