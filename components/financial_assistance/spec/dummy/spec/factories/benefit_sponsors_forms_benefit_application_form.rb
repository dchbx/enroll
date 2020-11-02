# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_forms_benefit_application, class: 'BenefitSponsors::Forms::BenefitApplicationForm' do
    start_on { TimeKeeper.date_of_record + 3.months }
    end_on  { TimeKeeper.date_of_record + 1.year + 3.months - 1.day }
    open_enrollment_start_on { TimeKeeper.date_of_record + 2.months }
    open_enrollment_end_on { TimeKeeper.date_of_record + 2.months + 20.day }
    benefit_sponsorship_id { "id" }

    trait :invalid_application do
      start_on { TimeKeeper.date_of_record + 3.months }
    end
  end
end
