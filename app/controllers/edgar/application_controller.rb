module Edgar
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def uploads
      render 'edgar/uploads', layout: 'edgar/application'
    end

    def earned_report_upload
      record = Edgar::Report.where(
        'created_at >= ?',
        report_params[:date].to_date || Time.zone.now.beginning_of_day
      ).first_or_create(name: 'Video Peqrformance Report')

      csv = CSV.parse(report_params['file'].tempfile.read)

      record.youtube_earned_data_raw = csv
      record.save!
      
      report_params['file'].tempfile.rewind
      Edgar::AWSClient.new(
        "daily-youtube-earned-performance-#{Time.zone.now.strftime('%d%m%Y')}.csv",
        StringIO.new(report_params['file'].tempfile.read)
      ).upload

      render nothing: true, status: :ok
    end

    private

    def report_params
      params.require(:report).permit(:file, :date)
    end
  end
end
