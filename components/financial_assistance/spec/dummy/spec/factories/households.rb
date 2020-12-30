# frozen_string_literal: true

FactoryBot.define do
  factory :household do
    family
    irs_group_id { "" }
    is_active { true }
    effective_starting_on {2.months.ago}
    effective_ending_on {2.months.ago}
    submitted_at {2.months.ago}
    # hbx_enrollments
    # tax_households
    # coverage_households
    # comments
  end
end
