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
      benefit_coverage_periods do
        [FactoryBot.build(:benefit_coverage_period, :open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, coverage_year: coverage_year)]
      end
    end

    trait :normal_ivl_open_enrollment_coverage_period do
      benefit_coverage_periods do
        [FactoryBot.build(:benefit_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, coverage_year: coverage_year)]
      end
    end

    trait :no_open_enrollment_coverage_period do
      benefit_coverage_periods do
        [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :next_years_no_open_enrollment_coverage_period, coverage_year: coverage_year)]
      end
    end

    trait :last_years_coverage_period do
      benefit_coverage_periods do
        [FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :last_years_coverage_period, coverage_year: coverage_year)]
      end
    end

    trait :normal_oe_period_with_past_coverage_periods do
      benefit_coverage_periods do
        [FactoryBot.build(:benefit_coverage_period, :last_years_no_open_enrollment_coverage_period, coverage_year: coverage_year), FactoryBot.build(:benefit_coverage_period, :no_open_enrollment_coverage_period, coverage_year: coverage_year),
         FactoryBot.build(:benefit_coverage_period, :next_years_open_enrollment_coverage_period, coverage_year: coverage_year)]
      end
    end
  end
end

