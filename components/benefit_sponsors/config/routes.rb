BenefitSponsors::Engine.routes.draw do

  namespace :profiles do
    resources :registrations do
      get :new_employer_profile_form, on: :collection
      post :create_employer_profile, on: :collection
      post :counties_for_zip_code, on: :collection
    end

    namespace :broker_agencies do
      resources :broker_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do
        collection do
          get :family_index
          get :messages
          get :staff_index
          get :agency_messages
          get :commission_statements
          get :general_agency_index
          post :email_guide
        end
        member do
          post :clear_assign_for_employer
          get :assign
          post :update_assign
          post :family_datatable
          get :inbox
          get :download_commission_statement
          get :show_commission_statement
        end
      end
      resources :broker_applicants

      resources :broker_roles

      resources :broker_agency_staff_roles do
        collection do
          get :search_broker_agency
          get :new_staff_member
          post :create_staff_member
        end
        member do
          get :approve
        end
      end
    end

    namespace :general_agencies do
      resources :general_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do
        collection do
          get :families
          get :messages
          get :staff_index
          get :agency_messages
          get :commission_statements
          get :employers
          get :staffs
          get :edit_staff
          post :update_staff
        end
        member do
          post :clear_assign_for_employer
          get :assign
          post :update_assign
          post :family_datatable
          get :inbox
          get :download_commission_statement
          get :show_commission_statement
        end
      end

      resources :general_agency_staff_roles do
        collection do
          get :search_general_agency
          get :new_staff_member
          post :create_staff_member
        end
        member do
          get :approve
        end
      end
    end
    namespace :employers do
      resources :employer_profiles, only: [:show] do
        get :export_census_employees
        post :bulk_employee_upload
        get :bulk_employee_upload
        get :coverage_reports
        post :terminate_employee_roster_enrollments
        collection do
          get :generate_sic_tree
          get :show_pending
        end
        member do
          get :inbox
          get :show_invoice
          get :download_invoice
        end

        resources :broker_agency, only: [:index, :show, :create] do
          collection do
            get :active_broker
          end
          get :terminate
        end
      end

      resources :employer_staff_roles do
        get :new_staff_member, on: :collection
        post :create_staff_member, on: :collection
        get :employer_search, on: :collection
        member do
          get :approve
        end
      end
    end
  end

  namespace :inboxes do
    resources :messages, only: [:show, :destroy] do
      get :msg_to_portal
    end
  end

  namespace :organizations do
    resource :office_locations do
      member do
        get :new
      end
    end
  end

  resources :benefit_sponsorships do
    resources :benefit_applications, controller: "benefit_applications/benefit_applications" do
      get :late_rates_check, on: :collection

      post :revert
      post :submit_application
      post :force_submit_application

      resources :benefit_packages, controller: "benefit_packages/benefit_packages" do
        get :calculate_employer_contributions, on: :collection
        get :calculate_employer_contributions, on: :member
        get :calculate_employee_cost_details, on: :collection
        get :calculate_employee_cost_details, on: :member
        get :reference_product_summary, on: :collection

        resources :sponsored_benefits, controller: "sponsored_benefits/sponsored_benefits" do
          member do
            get :calculate_employee_cost_details
            get :calculate_employer_contributions
          end

          collection do
            get :calculate_employee_cost_details
            get :calculate_employer_contributions
          end
        end
      end
    end
  end
end
