module PdfTemplates
  class BrokerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer, PdfTemplates::EmployerStaff
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :employer_name, String
    attribute :broker_agency, String
    attribute :mpi_indicator, String
    attribute :employer_profile, EmployerProfile
    attribute :broker_agency_profile, BrokerAgencyProfile
    attribute :terminated_broker_account, BrokerAgencyAccount
    attribute :first_name, String
    attribute :last_name, String
    attribute :termination_date, Date
    attribute :first_name, String
    attribute :last_name, String
    attribute :hbx_id, String
    attribute :employer_first_name, String
    attribute :employer_last_name, String

    def shop?
      return true
    end

    def general_agency_notice?
      return false
    end

    def broker?
      return true
    end

    def employee_notice?
      return false
    end
  end
end