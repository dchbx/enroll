# frozen_string_literal: true

FinancialAssistance::Engine.routes.draw do
  resources :applications do
    get :copy, on: :member
    put :step, on: :member
    put ':step/:step', on: :member, action: 'step'
    post :step, on: :collection
    get 'step/:step', on: :member, action: 'step', as: 'go_to_step'
    get 'help_paying_coverage', on: :collection, action: 'help_paying_coverage', as: 'help_paying_coverage'
    get 'application_checklist', on: :member, action: 'application_checklist', as: 'application_checklist'
    get 'get_help_paying_coverage_response', on: :collection, action: 'get_help_paying_coverage_response', as: 'get_help_paying_coverage_response'
    get 'render_message', on: :collection, action: 'render_message', as: 'render_message'
    get 'uqhp_flow', on: :collection, action: 'uqhp_flow', as: 'uqhp_flow'
    get :review_and_submit, on: :member
    get :review, on: :member
    get :eligibility_results, on: :member
    get :wait_for_eligibility_response, on: :member
    get :check_eligibility_results_received, on: :member
    get :application_publish_error, on: :member
    get :eligibility_response_error, on: :member
    get 'checklist_pdf', on: :collection, action: 'checklist_pdf', as: 'checklist_pdf'

    resources :relationships

    resources :applicants do
      put :step, on: :member
      put ':step/:step', on: :member, action: 'step'
      post :step, on: :collection
      get 'step/:step', on: :member, action: 'step', as: 'go_to_step'
      get :age_of_applicant
      get :primary_applicant_has_spouse
      get 'other_questions', on: :member, action: 'other_questions', as: 'other_questions'
      get 'save_questions', on: :member, action: 'save_questions', as: 'save_questions'
      get :immigration_document_options, on: :collection
      post :update, on: :member

      resources :incomes do
        get 'other', on: :collection
        put 'step(/:step)', action: 'step', on: :member
        post :step, on: :collection
        get 'step/:step', on: :member, action: 'step', as: 'go_to_step'
      end

      resources :benefits do
        put 'step(/:step)', action: 'step', on: :member
        post :step, on: :collection
        get 'step/:step', on: :member, action: 'step', as: 'go_to_step'
      end

      resources :deductions do
        put 'step(/:step)', action: 'step', on: :member
        post :step, on: :collection
        get 'step/:step', on: :member, action: 'step', as: 'go_to_step'
      end
    end
  end
end
