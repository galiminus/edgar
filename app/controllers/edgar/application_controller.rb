module Edgar
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def test
      render text: 'EDGAR IS UP AND RUNNING'
    end
  end
end
