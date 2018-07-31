FactoryGirl.define do
  factory :benefit_sponsors_members_dependent_member, class: 'BenefitSponsors::Members::DependentMember' do
    last_name     "Jetson"

    ssn do
      Forgery('basic').text(
        :exactly => 9,
        :allow_numeric  => true,
        :allow_lower    => false,
        :allow_upper    => false,
        :allow_special  => false
        )
    end

    trait :as_female_domestic_partner do
      kinship_to_primary_member :domestic_partner
      first_name    ["Olivia", "Ava", "Sophia", "Isabella", "Mia", "Charlotte", "Abigail", "Emily", "Harper"].sample
      gender        :female
      dob           { Date.today - 38.years }
    end

    trait :as_spouse do
      kinship_to_primary_member :spouse
      first_name    ["Olivia", "Ava", "Sophia", "Isabella", "Mia", "Charlotte", "Abigail", "Emily", "Harper"].sample
      gender        :female
      dob           { Date.today - 35.years }
    end

    trait :as_child do
      kinship_to_primary_member :child
      first_name    ["Liam", "William", "Mason", "James", "Benjamin", "Jacob", "Michael", "Elijah", "Ethan"].sample
      gender        :male
      dob           { Date.today - 7.years }
    end

  end
end
