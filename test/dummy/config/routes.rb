Rails.application.routes.draw do
  mount Edgar::Engine => "/edgar"
end
