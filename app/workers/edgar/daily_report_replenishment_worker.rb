module Edgar
  class DailyReportReplenishmentWorker
    include Sidekiq::Worker

    def perform(id)
      report = Edgar::Report.find(id)

      adwords = report.adwords_data
      yt = youtube = report.youtube_data
      youtube_earned = report.youtube_earned_data

      mxn2usd = JSON.parse(
        Faraday.get('https://api.fixer.io/latest?base=MXN').body
      )['rates']['USD'].to_f

      ts = adwords[:lines].map do |ads|

        yte = youtube_earned.select{ |line| line[:campaign] == ads[:campaign] }.last

        views = yt[:views].values.reduce(:+)
        cpv_currency = ads[:views] / ads[:cost]
        earned_paid_views_ratio = yte[:earned_views] / ads[:views]
        playbacks_percentage = yt[:monetized_playbacks] / views
        playbacks = yte[:earned_views] * playbacks_percentage
        real_cpv = (ads[:cost] * mxn2usd) / (ads[:views] + yte[:earned_views])
        real_cpm = yt[:monetized_playbacks] / yt[:revenue]
        estimated_earnings = yt[:monetized_playbacks] / real_cpm
        roi = (estimated_earnings - ads[:cost]) / ads[:cost]
        profit = estimated_earnings - (ads[:cost] * mxn2usd)
        cost_subscribers = yte[:earned_subscribers] / (ads[:cost] * mxn2usd)
        subscribers_percentage = yte[:earned_subscribers] / yt[:subescribers]

        return {
          series: ads[:campaign_id],
          tags: [
            report[:date].strftime('%d%m%Y'),
            report[:account_name],
            report[:account_id],
            ads[:campaign],
            ads[:campaign_id],
            'daily', 'video', 'performance', 'youtube', 'adwords', 'kpi'
          ],
          values: Hash.new(0).merge!(
            exchange_rate: mxn2usd,
            #date: ads[:day],
            views: views,
            impressions: ads[:impressions],
            paid_views: ads[:views],
            view_rate: ads[:view_rate],
            cost_paid_mxn: ads[:cost],
            #cost_paid_currency: ads[:acccount_currency_code],
            cpv_currency: cpv_currency,
            cpv_verification: ads[:average_cpv],
            earned_views: yte[:earned_views],
            earned_paid_views_ratio: earned_paid_views_ratio,
            playbacks_percentage: playbacks_percentage,
            estimated_playbacks: yt[:monetized_playbacks],
            playbacks: playbacks,
            total_earnings: yt[:revenue],
            real_cpv: real_cpv,
            real_cpm: real_cpm,
            estimated_earnings: estimated_earnings,
            roi: roi,
            profit: profit,
            total_subscribers: yt[:subscribers],
            earned_subscribers: yte[:earned_subscribers],
            cost_subscribers: cost_subscribers,
            subscribers_percentage: subscribers_percentage,
            earned_shares: yte[:earned_shares],
            earned_playlist: yte[:earned_playlist_additions]
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
