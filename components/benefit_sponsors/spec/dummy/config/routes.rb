Rails.application.routes.draw do
  mount BenefitSponsors::Engine => "/benefit_sponsors"

  devise_for :users

  root "welcome#index"
end
