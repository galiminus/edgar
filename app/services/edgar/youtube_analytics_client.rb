module Edgar

  # Provides a small wrapper for YouTube Analytics API.
  #
  #   client = YoutubeAnalyticsClient.new.core
  #
  class YoutubeAnalyticsClient
    def initialize
      youtube_account = Team.find_by_name(ENV['EDGAR_TEAM_NAME']).youtube_accounts[0]

      scopes = [
        'youtube',
        'youtube.readonly',
        'yt-analytics.readonly',
        'yt-analytics-monetary.readonly'
      ]

      Yt.configure do |config|
        config.client_id = ENV['YT_CLIENT_ID']
        config.client_secret = ENV['YT_CLIENT_SECRET']
      end
      
      @account = Yt::Account.new(
        refresh_token: youtube_account.refresh_token,
        scopes: scopes,
        expires_at: 0
      )      

      @owner = Yt::ContentOwner.new(
        owner_name: youtube_account.owner_name,
        refresh_token: youtube_account.refresh_token,
        scopes: scopes,
        expires_at: 0
      )
    end

    def account
      @account
    end

    def owner
      @owner
    end

    def for(id)
      Yt::Channel.new id: id, auth: @owner
    end
  end
end
