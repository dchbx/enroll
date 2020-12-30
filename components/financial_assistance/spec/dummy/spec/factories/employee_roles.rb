# frozen_string_literal: true

FactoryBot.define do
  factory :employee_role do
    association :person
    sequence(:ssn, 111_111_111)
    gender { "male" }
    dob  { Date.new(1965,1,1) }
    hired_on { 20.months.ago }

    after :build do |ee, _evaluator|
      ee.employer_profile = create(:employer_profile) if ee.employer_profile.blank?
    end
  end
end
