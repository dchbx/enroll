FactoryGirl.define do
  factory :benefit_sponsorship do
    service_markets %W(individual shop)
    benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period)] }

    trait :single_open_enrollment_coverage_period do
       benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period, :open_enrollment_coverage_period)] }
    end

    trait :open_enrollment_coverage_period do
       benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period, :open_enrollment_coverage_period), FactoryGirl.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period)] }
    end

    trait :no_open_enrollment_coverage_period do
       benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period, :no_open_enrollment_coverage_period), FactoryGirl.build(:benefit_coverage_period, :next_years_no_open_enrollment_coverage_period)] }
    end
  end
end
