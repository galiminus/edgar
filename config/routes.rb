Edgar::Engine.routes.draw do
  get 'uploads', to: 'application#uploads'
  post 'earned_report_upload', to: 'application#earned_report_upload'
end
