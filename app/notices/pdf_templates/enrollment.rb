module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[String]
    attribute :premium, String
    attribute :employee_cost, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :selected_on, Date
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :plan, PdfTemplates::Plan
    attribute :plan_year, Date
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :dependents, Array[String]
    attribute :dependent_dob, Date
  end
end
