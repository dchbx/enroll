FactoryBot.define do
  factory :benefit_sponsorship do
    transient do
      coverage_year { TimeKeeper.date_of_record.year }
    end

    service_markets { %W(individual shop) }
    benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, coverage_year: coverage_year)] }

    trait :single_open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :open_enrollment_coverage_period, coverage_year: coverage_year)] }
    end

    trait :open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, coverage_year: coverage_year)] }
    end

    trait :normal_ivl_open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, coverage_year: coverage_year)] }
    end

    trait :no_open_enrollment_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_no_open_enrollment_coverage_period, coverage_year: coverage_year)] }
    end

    trait :last_years_coverage_period do
      benefit_coverage_periods { [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :last_years_coverage_period, coverage_year: coverage_year)] }
    end
  end
end
