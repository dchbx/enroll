# frozen_string_literal: true

FactoryBot.define do
  factory :application, class: "::FinancialAssistance::Application" do

  end

  factory :financial_assistance_application, class: "::FinancialAssistance::Application" do
    assistance_year TimeKeeper.date_of_record.year
    submitted_at {2.months.ago}
    aasm_state "determined"
    parent_living_out_of_home_terms false

    trait :with_applicants do
      applicants do
        [
          FactoryBot.build(:financial_assistance_applicant, :male, :with_home_address, application: self, first_name: 'john', last_name: 'adams', family_member_id: BSON::ObjectId.new, dob: 40.years.ago, ssn: '472743442', is_primary_applicant: true, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :female, :spouse, :with_home_address, application: self, first_name: 'sarah', last_name: 'adams', dob: 35.years.ago, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :female, :child, :with_home_address, application: self, first_name: 'emma', last_name: 'adams', dob: 10.years.ago, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :male, :child, :with_home_address, application: self, first_name: 'marvin', last_name: 'adams', dob: 7.years.ago, citizen_status: 'alien_lawfully_present')
        ]
      end
    end

    after(:create) do |application, _evaluator|
      application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      application.save
    end
  end
end
