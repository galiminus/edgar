namespace :edgar do
  desc "Run DailyKeywordsPerformanceWorker"
  task :daily_keywords_performance => :environment do
    Edgar::DailyKeywordsPerformanceWorker.perform_async
  end

  desc "Run DailyVideoPerformanceWorker"
  task :daily_video_performance => :environment do
    Edgar::DailyVideoPerformanceWorker.perform_async
  end

  desc "Run DailyYoutubePerformanceWorker"
  task :daily_youtube_performance => :environment do
    Edgar::DailyYoutubePerformanceWorker.perform_async
  end
end
