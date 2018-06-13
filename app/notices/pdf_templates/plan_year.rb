module PdfTemplates
  class PlanYear
    include Virtus.model

    attribute :open_enrollment_start_on, Date
    attribute :open_enrollment_end_on, Date
    attribute :start_on, Date
    attribute :end_on, Date
    attribute :carrier_name, String
    attribute :warnings, Array[String]
    attribute :binder_payment_due_date, Date
    attribute :total_enrolled_count, Integer
    attribute :eligible_to_enroll_count, Integer
    attribute :renewing_start_on, Date
    attribute :terminated_on, Date
    attribute :binder_payment_total, Money
  end
end
