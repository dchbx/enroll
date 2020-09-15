# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_income, class: 'FinancialAssistance::Income' do

    title 'Test'
    amount 10
    frequency_kind 'monthly'
    start_on Date.today.beginning_of_month
    end_on Date.today.end_of_month
  end
end