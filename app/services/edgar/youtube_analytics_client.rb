module Edgar

  # Provides a small wrapper for YouTube Analytics API.
  #
  #   client = YoutubeAnalyticsClient.new.core
  #
  class YoutubeAnalyticsClient
    def initialize
      Yt.configure do |config|
        config.client_id = ENV['YOUTUBE_CLIENT_ID']
        config.client_secret = ENV['YOUTUBE_CLIENT_SECRET']
      end
      
      @client = Yt::Account.new(
        refresh_token: Team.find(3).adwords_refresh_token,
        expires_at: 0
      )      
    end

    def core
      @client
    end
  end
end
