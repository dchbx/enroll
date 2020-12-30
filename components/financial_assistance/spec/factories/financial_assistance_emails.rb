# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_email, class: "::FinancialAssistance::Locations::Email" do
    kind { 'home' }
    sequence(:address) { |n| "example#{n}@example.com" }
  end
end
