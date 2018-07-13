BenefitMarkets::Engine.routes.draw do
  resources :sites, only: [] do
    resources :benefit_markets, only: [:index, :new, :create], shallow: true
  end

  resources :benefit_markets, only: [:new, :create, :show, :edit, :update] do
    resource :configuration
  end

  namespace :products do
    resources :product_packages, only: [:index, :new, :create]

    resources :benefit_market_catalogs, only: [] do
      resources :product_packages, only: [:show, :edit, :update, :destroy]
    end
  end
  resources :benefit_markets, only: [:show, :edit, :update, :destroy]
end
