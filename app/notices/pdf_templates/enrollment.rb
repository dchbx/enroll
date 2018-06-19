module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[Individual]
    attribute :premium, String
    attribute :employee_cost, String
    attribute :employer_contribution, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :terminated_on, Date
    attribute :selected_on, Date
    attribute :created_at, Date
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :plan, PdfTemplates::Plan
    attribute :coverage_kind, String
    attribute :kind, String
    attribute :is_receiving_assistance, Boolean, :default => false
    attribute :plan_year, Date
    attribute :shop_open_enrollment_start_on, Date
    attribute :shop_open_enrollment_end_on, Date
    attribute :dependents, Array[String]
    attribute :dependent_dob, Date
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :employee_fullname, String
    attribute :dependents, String
    attribute :dependents_count, String
    attribute :enrolled_count, String
  end
end
