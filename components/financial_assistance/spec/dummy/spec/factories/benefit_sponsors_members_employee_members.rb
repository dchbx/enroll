# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_members_employee_member, class: 'BenefitSponsors::Members::EmployeeMember' do
    last_name     { "Jetson" }
    dob           { Date.today - 45.years }
    date_of_hire  { Date.today - 3.years }

    ssn do
      Forgery('basic').text(
        :exactly => 9,
        :allow_numeric => true,
        :allow_lower => false,
        :allow_upper => false,
        :allow_special => false
      )
    end

    trait :as_male do
      gender        { :male }
      first_name    { ["Liam", "William", "Mason", "James", "Benjamin", "Jacob", "Michael", "Elijah", "Ethan"].sample }
    end

    trait :as_female do
      first_name    { ["Olivia", "Ava", "Sophia", "Isabella", "Mia", "Charlotte", "Abigail", "Emily", "Harper"].sample }
      gender        { :female }
    end


  end
end
