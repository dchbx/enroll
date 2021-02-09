FactoryBot.define do
  factory :benefit_coverage_period do
    transient do
      coverage_year { TimeKeeper.date_of_record.year }
    end

    service_market           { "individual" }
    start_on                 { Date.new(coverage_year, 1, 1) }
    end_on                   { Date.new(coverage_year, 12, 31) }
    open_enrollment_start_on { Date.new(coverage_year - 1, 11, 1) }
    open_enrollment_end_on   { Date.new(coverage_year, 1, 31) }
    benefit_packages { [FactoryBot.build(:benefit_package, coverage_year: coverage_year)] }

    trait :open_enrollment_coverage_period do
      start_on                 { Date.new(coverage_year, 1, 1) }
      end_on                   { Date.new(coverage_year, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year, 1, 1) }
      open_enrollment_end_on   { Date.new(coverage_year, 12, 31) }
      benefit_packages { [FactoryBot.build(:benefit_package, coverage_year: coverage_year)] }
    end

    trait :no_open_enrollment_coverage_period do
      start_on                 { Date.new(coverage_year, 1, 1) }
      end_on                   { Date.new(coverage_year, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year, 1, 1) }
      open_enrollment_end_on   { Date.new(coverage_year, 1, 1) }
      benefit_packages { [FactoryBot.build(:benefit_package, coverage_year: coverage_year)] }
    end

    trait :next_years_open_enrollment_coverage_period do
      start_on                 { Date.new(coverage_year + 1, 1, 1) }
      end_on                   { Date.new(coverage_year + 1, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year, 11, 1) }
      open_enrollment_end_on   { Date.new(coverage_year + 1, 2, 3) }
      benefit_packages { [FactoryBot.build(:benefit_package, :next_coverage_year_title, coverage_year: coverage_year)] }
    end

    trait :next_years_no_open_enrollment_coverage_period do
      start_on                 { Date.new(coverage_year + 1, 1, 1) }
      end_on                   { Date.new(coverage_year + 1, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year + 1, 1, 1) }
      open_enrollment_end_on   { Date.new(coverage_year + 1, 1, 1) }
      benefit_packages { [FactoryBot.build(:benefit_package, :next_coverage_year_title, coverage_year: coverage_year)] }
    end

    trait :last_years_coverage_period do
      start_on                 { Date.new(coverage_year - 1, 1, 1) }
      end_on                   { Date.new(coverage_year - 1, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year - 2, 11, 1) }
      open_enrollment_end_on   { Date.new(coverage_year - 1, 2, 3) }
      benefit_packages { [FactoryBot.build(:benefit_package, :last_coverage_year_title, coverage_year: coverage_year)] }
    end

    trait :last_years_no_open_enrollment_coverage_period do
      start_on                 { Date.new(coverage_year - 1, 1, 1) }
      end_on                   { Date.new(coverage_year - 1, 12, 31) }
      open_enrollment_start_on { Date.new(coverage_year - 1, 1, 1) }
      open_enrollment_end_on   { Date.new(coverage_year - 1, 1, 1) }
      benefit_packages { [FactoryBot.build(:benefit_package, :last_coverage_year_title, coverage_year: coverage_year)] }
    end
  end
end
