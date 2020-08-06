# frozen_string_literal: true

SponsoredBenefits::Engine.routes.draw do

  resources :plan_design_proposals, only: [] do
    resources :plan_design_census_employees, controller: 'census_members/plan_design_census_employees' do
      collection do
        post :bulk_employee_upload
        post :expected_selection
        get  :export_plan_design_employees
      end
    end
  end

  namespace :organizations do

    get "plan_design_proposals/:employer_profile_id/claim", to: "plan_design_proposals#claim", as: "plan_design_proposal_claim"

    resources :broker_agency_profiles, only: :employers do
      get :employers, on: :member
    end

    resources :general_agency_profiles, only: [:index] do
      collection do
        post :assign
        post :fire
        post :set_default
        post :clear_default
      end
    end

    resources :plan_design_organizations do
      resources :plan_design_proposals do
        resources :contributions, controller: 'plan_design_proposals/contributions', only: [:index]
      end
      resources :carriers, controller: 'plan_design_proposals/carriers', only: [:index]
      resources :plans, controller: 'plan_design_proposals/plans', only: [:index]
      post :dental_reference_plans, action: :dental_reference_plans, controller: 'plan_design_proposals/plans'
    end

    resources :plan_design_proposals, only: [:destroy, :create, :show] do
      resources :contributions, controller: 'plan_design_proposals/contributions', only: [:index]
      resources :plan_selections, controller: 'plan_design_proposals/plan_selections', only: [:new]
      resources :plan_reviews, controller: 'plan_design_proposals/plan_reviews', only: [:new] do
        collection do
          get :show
        end
      end
      resources :proposal_copies, controller: 'plan_design_proposals/proposal_copies', only: [:create]
      resources :benefit_groups, controller: 'plan_design_proposals/benefit_groups', only: [:create, :destroy]
      resources :plan_comparisons, controller: 'plan_design_proposals/plan_comparisons', only: [:new] do
        collection do
          get :export
          get :csv, defaults: { format: :csv }
        end
      end
      post :publish

      resources :plan_exports, controller: 'plan_design_proposals/plan_exports', only: [:create] do
      end

    end

    resource :office_locations do
      member do
        get :new
      end
    end
  end
end
