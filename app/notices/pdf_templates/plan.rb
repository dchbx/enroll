module PdfTemplates
  class Plan
    include Virtus.model

    attribute :open_enrollment_start_on, Date
    attribute :open_enrollment_end_on, Date
    attribute :coverage_start_on, Date
    attribute :coverage_end_on, Date
    attribute :plan_name, String
    attribute :metal_level, String
    attribute :coverage_kind, String
    attribute :plan_carrier, String
    attribute :hsa_plan, Boolean
    attribute :renewal_plan_type, String
  end
end
