# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  match 'families/home', to: 'insured/families#home', via: [:get], as: "family_account"

  namespace :insured do
    resources :family_members
    resources :families do
      collection do
        get 'inbox'
        get 'manage_family'
      end
    end
  end

  mount FinancialAssistance::Engine => "/financial_assistance"
end
