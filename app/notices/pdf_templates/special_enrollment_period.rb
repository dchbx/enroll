module PdfTemplates
  class SpecialEnrollmentPeriod
    include Virtus.model

    attribute :title, String
    attribute :qle_on, Date
    attribute :start_on, Date
    attribute :end_on, Date
    
  end
end
