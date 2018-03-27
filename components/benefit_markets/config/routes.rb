BenefitMarkets::Engine.routes.draw do
  resources :sites, only: [] do
    resources :benefit_markets, shallow_nested: true
  end

  resources :benefit_markets, only: [] do
    resource :configuration
  end
end
