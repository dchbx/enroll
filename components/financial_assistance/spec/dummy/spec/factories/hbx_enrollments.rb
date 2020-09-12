# frozen_string_literal: true

FactoryBot.define do
  factory :hbx_enrollment do
    kind { "employer_sponsored" }
    elected_premium_credit { 0 }
    applied_premium_credit { 0 }
    effective_on {1.month.ago.to_date}
    terminated_on { nil }
    waiver_reason { "this is the reason" }
    # broker_agency_id nil
    # writing_agent_id nil
    submitted_at {2.months.ago}
    aasm_state { "coverage_selected" }
    aasm_state_date {effective_on}
    updated_by { "factory" }
    is_active { true }
    enrollment_kind { "open_enrollment" }
    # hbx_enrollment_members
    # comments

    transient do
      enrollment_members { [] }
      active_year { TimeKeeper.date_of_record.year }
    end

    # plan { create(:plan, :with_rating_factors, :with_premium_tables, active_year: active_year) }

    trait :with_enrollment_members do
      hbx_enrollment_members { enrollment_members.map{|member| FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: self, is_subscriber: member.is_primary_applicant, coverage_start_on: self.effective_on, eligibility_date: self.effective_on) }}
    end

    trait :shop do
      kind { "employer_sponsored" }
      aasm_state { "coverage_selected" }
    end

    trait :cobra_shop do
      kind { "employer_sponsored_cobra" }
      aasm_state { "coverage_selected" }
    end

    trait :health_plan do
      active_individual_health_plan
    end

    trait :with_product do
      product {  FactoryBot.create(:benefit_markets_products_product) }
    end

    trait :coverage_selected do
      aasm_state { "coverage_selected" }
    end

    trait :open_enrollment do
      enrollment_kind  { "open_enrollment" }
    end

    trait :special_enrollment do
      enrollment_kind { special_enrollment }
    end

    trait :terminated do
      aasm_state { "coverage_terminated" }
      terminated_on { Time.now.last_month.end_of_month }
      termination_submitted_on { TimeKeeper.date_of_record }
    end

    trait :older_effective_date do
      effective_on {Date.new(active_year,4,1)}
    end

    trait :newer_effective_date do
      effective_on {Date.new(active_year,5,1)}
    end

    factory :shop_health_enrollment,             traits: [:shop, :health_plan]
  end
end
