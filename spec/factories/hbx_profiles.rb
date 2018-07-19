FactoryGirl.define do
  factory :hbx_profile do
    organization            { FactoryGirl.build(:organization) }
    us_state_abbreviation   Settings.aca.state_abbreviation
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

    trait :last_years_coverage_period do
      benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :last_years_coverage_period) }
    end
  end
end
