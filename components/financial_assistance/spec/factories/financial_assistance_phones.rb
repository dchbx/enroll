# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_phone, class: "::FinancialAssistance::Locations::Phone" do
    kind { 'home' }
    area_code { 202 }
    sequence(:number, 1111111) { |n| "#{n}"}
    sequence(:extension) { |n| "#{n}"}
  end
end
