Edgar::Engine.routes.draw do
  resources :reports, only: [:index, :show]
  get 'uploads', to: 'application#uploads'
  post 'earned_report_upload', to: 'application#earned_report_upload'
end
