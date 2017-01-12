FactoryGirl.define do
  factory :benefit_coverage_period do
    service_market           "individual"
    start_on                 { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
    end_on                   { Date.new(TimeKeeper.date_of_record.year, 12, 31) }
    open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year - 1, 11, 1) }
    open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year, 1, 31) }
    benefit_packages { [ FactoryGirl.build(:benefit_package) ] }

    trait :open_enrollment_coverage_period do
      start_on                 { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      end_on                   { Date.new(TimeKeeper.date_of_record.year, 12, 31) }
      open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year, 12, 31) }
      benefit_packages { [ FactoryGirl.build(:benefit_package) ] }
    end

    trait :no_open_enrollment_coverage_period do
      start_on                 { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      end_on                   { Date.new(TimeKeeper.date_of_record.year, 12, 31) }
      open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      benefit_packages { [ FactoryGirl.build(:benefit_package) ] }
    end

    trait :next_years_open_enrollment_coverage_period do
      start_on                 { Date.new(TimeKeeper.date_of_record.year + 1 , 1, 1) }
      end_on                   { Date.new(TimeKeeper.date_of_record.year + 1, 12, 31) }
      open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year, 11, 1) }
      open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year + 1, 2, 3) }
      benefit_packages { [ FactoryGirl.build(:benefit_package, :next_coverage_year_title) ] }
    end

    trait :next_years_no_open_enrollment_coverage_period do
      start_on                 { Date.new(TimeKeeper.date_of_record.year + 1 , 1, 1) }
      end_on                   { Date.new(TimeKeeper.date_of_record.year + 1, 12, 31) }
      open_enrollment_start_on { Date.new(TimeKeeper.date_of_record.year + 1, 1, 1) }
      open_enrollment_end_on   { Date.new(TimeKeeper.date_of_record.year + 1, 1, 1) }
      benefit_packages { [ FactoryGirl.build(:benefit_package, :next_coverage_year_title) ] }
    end
  end
end
