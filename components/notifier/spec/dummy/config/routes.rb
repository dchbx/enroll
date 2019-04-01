Rails.application.routes.draw do

  mount Notifier::Engine => "/notifier"
end
