# frozen_string_literal: true

# Date.today converted to TimeKeeper

FactoryBot.define do
  factory :enrollee do
    coverage_start_on { TimeKeeper.date_of_record }
    person
  end
end
