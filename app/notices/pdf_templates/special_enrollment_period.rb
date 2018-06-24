module PdfTemplates
  class SpecialEnrollmentPeriod
    include Virtus.model

    attribute :title, String
    attribute :reason, String
    attribute :qle_on, Date
    attribute :start_on, Date
    attribute :end_on, Date
    attribute :effective_on, Date
  end
end
