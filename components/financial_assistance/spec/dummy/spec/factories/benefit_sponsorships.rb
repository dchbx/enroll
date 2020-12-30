# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsorship do
    service_markets { %w[individual shop] }
    benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period)] }

    trait :single_open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :open_enrollment_coverage_period)] }
    end

    trait :open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :open_enrollment_coverage_period), FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period)] }
    end

    trait :no_open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period), FactoryBot.build(:benefit_coverage_period, :next_years_no_open_enrollment_coverage_period)] }
    end

    trait :last_years_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period), FactoryBot.build(:benefit_coverage_period, :last_years_coverage_period)] }
    end
  end
end
