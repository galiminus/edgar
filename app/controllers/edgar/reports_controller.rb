module Edgar
  class ReportsController < ActionController::Base
    protect_from_forgery with: :exception

    def index
      @reports = Edgar::Report.completion.page(params[:page]).per(100)

      render 'edgar/index', layout: 'edgar/application'
    end

    def show
      report = Edgar::Report.find(params[:id])

      send_data report.to_csv,
        filename: "edgar-report-replenishment-#{report.account_id}-#{report.date.strftime('%d%m%Y')}.csv",
        type: 'text/csv, charset=utf-8, header=present'
    end
  end
end
