Rails.application.routes.draw do

  devise_for :users, :controllers => { :registrations => "users/registrations", :sessions => 'users/sessions' }

  get 'check_time_until_logout' => 'session_timeout#check_time_until_logout', :constraints => { :only_ajax => true }
  get 'reset_user_clock' => 'session_timeout#reset_user_clock', :constraints => { :only_ajax => true }
  post 'show_hints' => 'welcome#show_hints', :constraints => { :only_ajax => true }

  namespace :users do
    resources :orphans, only: [:index, :show, :destroy]
  end

  resources :saml, only: [] do
    collection do
      post :login
      get :logout
      get :navigate_to_assistance
    end
  end

  namespace :exchanges do
    resources :inboxes, only: [:show, :destroy]
    resources :announcements, only: [:index, :create, :destroy] do
      get :dismiss, on: :collection
    end
    resources :agents_inboxes, only: [:show, :destroy]
    resources :hbx_profiles do
      root 'hbx_profiles#show'

      collection do
        get :family_index
        get :employer_index
        get :employer_invoice
        post :employer_invoice_datatable
        post :generate_invoice
        get :broker_agency_index
        get :general_agency_index
        get :issuer_index
        get :product_index
        get :configuration
        post :set_date
        post :update_setting
        get :staff_index
        get :assister_index
        get :request_help
        get :binder_index
        get :binder_index_datatable
        post :binder_paid
        get :verification_index
        get :verifications_index_datatable
      end

      member do
        post :transmit_group_xml
        get :home
        get :inbox
      end

      # resources :hbx_staff_roles, shallow: true do
      resources :hbx_staff_roles do
        # root 'hbx_profiles/hbx_staff_roles#show'
      end
    end

    resources :agents do
      collection do
        get :home
        get :begin_consumer_enrollment
        get :begin_employee_enrollment
        get :resume_enrollment
        get :show
      end
      member do
        get :inbox
      end
    end

    resources :broker_applicants

    # get 'hbx_profiles', to: 'hbx_profiles#welcome'
    # get 'hbx_profiles/:id', to: 'hbx_profiles#show', as: "my_account"
    # get 'hbx_profiles/new'
    # get 'hbx_profiles/create'
    # get 'hbx_profiles/update'
    # get 'hbx_profiles/broker_agency_index'
    # get 'hbx_profiles/insured_index'
  end

  namespace :insured do
    get 'verification_documents/upload', to: 'verification_documents#upload'
    post 'verification_documents/upload', to: 'verification_documents#upload'
    get 'verification_documents/download/:key', to: 'verification_documents#download'

    resources :plan_shoppings, :only => [:show] do
      member do
        get 'plans'
        get 'receipt'
        get 'print_waiver'
        post 'checkout'
        get 'thankyou'
        post 'waive'
        post 'terminate'
        post 'set_elected_aptc'
      end
    end

    resources :interactive_identity_verifications, only: [:create, :new, :update]

    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :families, only: [:show] do
      get 'new'
      member do
        post 'unblock'
        delete 'delete_consumer_broker'
      end

      collection do
        get 'home'
        get 'manage_family'
        get 'personal'
        get 'inbox'
        get 'brokers'
        get 'verification'
        get 'document_upload'
        get 'find_sep'
        post 'record_sep'
        get 'check_qle_date'
        get 'check_move_reason'
        get 'check_insurance_reason'
        get 'purchase'
        get 'family'
        get 'upload_notice_form'
        post 'upload_notice'
      end

      resources :people do
        collection do
          get 'search'
        end
      end
    end

    resources :consumer_role, controller: 'consumer_roles', only: [:create, :edit, :update] do
      get :ssn_taken, on: :collection
      get :search, on: :collection
      get :privacy, on: :collection
      post :match, on: :collection
      post :build, on: :collection
      get :ridp_agreement, on: :collection
      get :immigration_document_options, on: :collection
      ##get :privacy, on: :collection
    end

    resources :employee, :controller=>"employee_roles", only: [:create, :edit, :update, :show] do
      collection do
        get 'new_message_to_broker'
        post 'send_message_to_broker'
        post :match
        get 'search'
        get 'privacy'
        get 'welcome'
      end
    end

    root 'families#home'

    resources :family_members
    resources :group_selections, controller: "group_selection", only: [:new, :create] do
      collection do
        post :terminate
        get :terminate_selection
        get :terminate_confirm
      end
    end

  end

  namespace :employers do
    post 'search', to: 'employers#search'
    root 'employer_profiles#new'

    resources :premium_statements, :only => [:show]

    resources :employer_staff_roles, :only => [:create, :destroy] do
      member do
        get :approve
      end
    end

    #TODO REFACTOR
    resources :people do
      collection do
        get 'search'
        post 'match'
      end
    end
    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :employer_profiles do
      get 'new'
      get 'my_account'
      get 'show_profile'
      get 'consumer_override'
      get 'export_census_employees'
      get 'bulk_employee_upload_form'
      post 'bulk_employee_upload'
      member do
        get "download_invoice"
      end
      collection do
        get 'welcome'
        get 'search'
        post 'match'
        get 'inbox'
      end
      resources :plan_years do
        get 'reference_plans'
        get 'dental_reference_plans'
        get 'generate_dental_carriers_and_plans'
        get 'plan_details' => 'plan_years#plan_details', on: :collection
        get 'recommend_dates', on: :collection
        get 'reference_plan_options', on: :collection
        post 'revert'
        post 'publish'
        post 'force_publish'
        get 'search_reference_plan', on: :collection
        post 'make_default_benefit_group'
        post 'delete_benefit_group'
        get 'calc_employer_contributions', on: :collection
        get 'calc_offered_plan_contributions', on: :collection
        get 'employee_costs', on: :collection
        get 'reference_plan_summary', on: :collection

      end

      resources :broker_agency, only: [:index, :show, :create] do
        collection do
          get :active_broker
        end
        get :terminate
      end

      resources :census_employees, only: [:new, :create, :edit, :update, :show] do
        get :delink
        get :terminate
        get :rehire
        get :benefit_group, on: :member
      end
    end
  end

  # match 'thank_you', to: 'broker_roles#thank_you', via: [:get]
  match 'broker_registration', to: 'broker_agencies/broker_roles#new_broker_agency', via: [:get]

  namespace :carriers do
    resources :carrier_profiles do
    end
  end

  namespace :broker_agencies do
    root 'profiles#new'
    resources :inboxes, only: [:new, :create, :show, :destroy] do
      get :msg_to_portal
    end
    resources :profiles, only: [:new, :create, :show, :index, :edit, :update] do
      get :inbox

      collection do
        get :family_index
        get :employers
        get :messages
        get :staff_index
        get :agency_messages
        get :assign_history
      end
      member do
        get :general_agency_index
        get :manage_employers
        post :clear_assign_for_employer
        get :assign
        post :update_assign
        post :set_default_ga
      end

      resources :applicants
    end
    resources :broker_roles, only: [:create] do
      root 'broker_roles#new_broker'
      collection do
        get :new_broker
        get :new_staff_member
        get :new_broker_agency
        get :search_broker_agency
      end
      member do
        get :favorite
      end
    end
  end

  match 'general_agency_registration', to: 'general_agencies/profiles#new_agency', via: [:get]
  namespace :general_agencies do
    root 'profiles#new'
    resources :profiles do
      collection do
        get :new_agency_staff
        get :search_general_agency
        get :new_agency
        get :messages
        get :agency_messages
        get :inbox
        get :edit_staff
        post :update_staff
      end
      member do
        get :employers
        get :families
        get :staffs
      end
    end
    resources :inboxes, only: [:new, :create, :show, :destroy] do
      get :msg_to_portal
    end
  end

  resources :translations

  namespace :api, :defaults => {:format => 'xml'} do
    namespace :v1 do
      resources :slcsp, :only => []  do
        collection do
          post :plan
        end
      end
    end
  end

  ############################# TO DELETE BELOW ##############################

  # FIXME: Do this properly later
  namespace :products do
    resources :plans, controller: :qhp, :only => [] do
      collection do
        get 'comparison'
        get 'summary'
      end
    end
  end

  resources :people do #TODO Delete
    get 'select_employer'
    get 'my_account'

    collection do
      post 'person_confirm'
      post 'plan_details'
      get 'check_qle_marriage_date'
    end

    member do
      get 'get_member'
    end

  end

  match 'families/home', to: 'insured/families#home', via:[:get], as: "family_account"

  match "hbx_profiles/edit_dob_ssn" => "exchanges/hbx_profiles#edit_dob_ssn", as: :edit_dob_ssn, via: [:get, :post]
  match "hbx_profiles/update_dob_ssn" => "exchanges/hbx_profiles#update_dob_ssn", as: :update_dob_ssn, via: [:get, :post], defaults: { format: 'js' }
  match "hbx_profiles/verify_dob_change" => "exchanges/hbx_profiles#verify_dob_change", as: :verify_dob_change, via: [:get], defaults: { format: 'js' }

  resources :families do
    get 'page/:page', :action => :index, :on => :collection

    resources :family_members, only: [:index, :new, :create]
    resources :households
  end

  resources :family_members, only: [:show, :edit, :update] do
    member do
      get :link_employee
      get :challenge_identity
    end
  end

  resources :invitations, only: [] do
    member do
      get :claim
    end
  end
  resources :office_locations, only: [:new]

  get "document/download/:bucket/:key" => "documents#download", as: :document_download
  get "document/authorized_download/:model/:model_id/:relation/:relation_id" => "documents#authorized_download", as: :authorized_document_download


  resources :documents, only: [:update, :destroy, :update] do
    collection do
      put :change_person_aasm_state
      get :show_docs
      put :update_verification_type
      get :enrollment_verification
      put :enrollment_docs_state
      put :extend_due_date
      get :fed_hub_request
    end
  end

  # Temporary for Generic Form Template
  match 'templates/form-template', to: 'welcome#form_template', via: [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  #
  # You can have the root of your site routed with "root"
  root 'welcome#index'
end
