FactoryGirl.define do
  factory :financial_assistance_benefit, class: 'FinancialAssistance::Benefit' do

    association :applicant

    title 'DUMMY_TITLE	'
    insurance_kind "medicare_part_b"
    kind "is_eligible"
  end
end
