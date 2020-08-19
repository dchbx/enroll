Rails.application.routes.draw do
  resources :surveys do
    post 'step', on: :collection
    get 'previous_step', on: :collection
  end
end
