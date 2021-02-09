FactoryBot.define do
  factory :hbx_profile do
    transient do
      coverage_year { TimeKeeper.date_of_record.year }
    end

    organization            { FactoryBot.build(:organization) }
    us_state_abbreviation   { Settings.aca.state_abbreviation }
    cms_id   { "DC0" }
    benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, coverage_year: coverage_year) }

    trait :open_enrollment_coverage_period do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :open_enrollment_coverage_period, coverage_year: coverage_year) }
    end

    trait :normal_ivl_open_enrollment do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :normal_ivl_open_enrollment_coverage_period, coverage_year: coverage_year) }
    end

    trait :single_open_enrollment_coverage_period do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :single_open_enrollment_coverage_period, coverage_year: coverage_year) }
    end

    trait :no_open_enrollment_coverage_period do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :no_open_enrollment_coverage_period, coverage_year: coverage_year) }
    end

    trait :last_years_coverage_period do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :last_years_coverage_period, coverage_year: coverage_year) }
    end

    trait :current_oe_period_with_past_coverage_periods do
      benefit_sponsorship { FactoryBot.build(:benefit_sponsorship, :normal_oe_period_with_past_coverage_periods, coverage_year: coverage_year) }
    end
  end
end
