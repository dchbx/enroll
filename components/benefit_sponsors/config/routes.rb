BenefitSponsors::Engine.routes.draw do
  namespace :profiles do
    namespace :broker_agencies do
      resources :broker_roles, only: [:create] do
        collection do
          get :new_broker
          get :new_staff_member
          get :new_broker_agency, as: 'broker_registration'
          get :search_broker_agency
        end
      end

      resources :broker_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do

        collection do
          get :messages
        end
        member do
          get :assign
        end
      end
    end

    namespace :employers do
      resources :employer_profiles
      resources :employer_staff_roles
    end
  end

  namespace :organizations do
    resource :office_locations do
      member do
        get :new
      end
    end
  end

  resources :sites
end
