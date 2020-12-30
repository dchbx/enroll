# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_package do
    title {"individual_health_benefits_#{TimeKeeper.date_of_record.year}"}
    elected_premium_credit_strategy { "unassisted" }
    benefit_begin_after_event_offsets { [30, 60, 90] }
    benefit_effective_dates { ["first_of_month"] }
    benefit_categories { ["health"]}

    after :build do |bp|

    end

    trait :next_coverage_year_title do
      title {"individual_health_benefits_#{TimeKeeper.date_of_record.year + 1}"}
    end

    trait :last_coverage_year_title do
      title {"individual_health_benefits_#{TimeKeeper.date_of_record.year - 1}"}
    end
  end
end
