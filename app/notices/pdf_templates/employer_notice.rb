module PdfTemplates
  class EmployerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :employer_name, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :open_enrollment_end_on, Date
    attribute :coverage_end_on, Date
    attribute :coverage_start_on, Date
    attribute :to, String
    attribute :plan, PdfTemplates::Plan
    attribute :trigger_type, String

    def shop?
      return true
    end
  end
end
