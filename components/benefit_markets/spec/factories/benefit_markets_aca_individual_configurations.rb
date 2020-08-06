# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_aca_individual_configuration, class: 'BenefitMarkets::Configurations::AcaIndividualConfiguration' do
    after :build do |configuration|
      configuration.initial_application_configuration = build :benefit_markets_aca_individual_initial_application_configuration, configuration: configuration
    end
  end
end

