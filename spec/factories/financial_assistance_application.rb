FactoryBot.define do
  factory :financial_assistance_application, class: 'FinancialAssistance::Application' do
    association :family    
  end
end
