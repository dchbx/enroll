FactoryGirl.define do
  factory :plan_year do
    employer_profile

    start_on { (TimeKeeper.date_of_record).beginning_of_month }

    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 30).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 1.weeks }
    fte_count { 5 }
  end

  factory :next_month_plan_year, class: PlanYear do
    employer_profile
    start_on { (TimeKeeper.date_of_record).next_month.beginning_of_month }
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 32).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 2.weeks }
    aasm_state "published"
    fte_count { 5 }
  end

  factory :renewing_plan_year, class: PlanYear do
    employer_profile
    start_on { (TimeKeeper.date_of_record).next_month.beginning_of_month }
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 32).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 2.weeks }
    aasm_state "renewing_enrolling"
    fte_count { 5 }
  end

  factory :plan_year_not_started, class: PlanYear do
    employer_profile
    start_on { (TimeKeeper.date_of_record + 90).beginning_of_month }
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 30).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 1.weeks }
    fte_count { 5 }
  end
end
