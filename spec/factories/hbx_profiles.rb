FactoryGirl.define do
  factory :hbx_profile do
    organization            { FactoryGirl.build(:organization) }
    us_state_abbreviation   "DC"
    cms_id   "DC0"
    benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship) }

    trait :open_enrollment_coverage_period do
       benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :open_enrollment_coverage_period) }
    end

    trait :single_open_enrollment_coverage_period do
       benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :single_open_enrollment_coverage_period) }
    end

    trait :no_open_enrollment_coverage_period do
      benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :no_open_enrollment_coverage_period) }
    end
  end
end
