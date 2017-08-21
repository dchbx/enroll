module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[Individual]
    attribute :premium, String
    attribute :employee_cost, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :selected_on, Date
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :plan, PdfTemplates::Plan
    attribute :coverage_kind, String
    attribute :kind, String
    attribute :is_receiving_assistance, Boolean
    attribute :plan_year, Date
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
  end
end
