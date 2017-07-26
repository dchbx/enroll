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

    trait :with_benefit_group_congress do
      benefit_groups { [FactoryGirl.build(:benefit_group_congress)] }
    end

    trait :with_benefit_group do
      benefit_groups { [FactoryGirl.build(:benefit_group, effective_on_kind: "first_of_month")] }
    end

  end

  factory :future_plan_year, class: PlanYear do
    employer_profile
    start_on { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 32).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 2.weeks }
    aasm_state "enrolling"
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
    start_on { (TimeKeeper.date_of_record + 3.months).beginning_of_month }
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { (start_on - 1.month).beginning_of_month }
    open_enrollment_end_on { open_enrollment_start_on + 1.weeks }
    fte_count { 5 }
  end


  factory :custom_plan_year, class: PlanYear do

    transient do
      renewing false
      with_dental false
      reference_plan {FactoryGirl.create(:plan, :with_premium_tables)._id}
      dental_reference_plan nil
    end

    employer_profile
    start_on TimeKeeper.date_of_record.beginning_of_month
    end_on { start_on + 1.year - 1.day }
    open_enrollment_start_on { start_on - 1.month }
    imported_plan_year true

    open_enrollment_end_on do
      end_date = renewing ? Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on : Settings.aca.shop_market.open_enrollment.monthly_end_on
      Date.new(open_enrollment_start_on.year, open_enrollment_start_on.month, end_date)
    end

    after(:create) do |custom_plan_year, evaluator|
      if evaluator.with_dental
        create(:benefit_group, :with_valid_dental, plan_year: custom_plan_year, reference_plan_id: evaluator.reference_plan, dental_reference_plan_id: evaluator.dental_reference_plan)
      else
        create(:benefit_group, plan_year: custom_plan_year, reference_plan_id: evaluator.reference_plan)
      end
    end
  end
end
