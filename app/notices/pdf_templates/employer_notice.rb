module PdfTemplates
  class EmployerNotice
   include Virtus.model

    attribute :notification_type, String
    attribute :mpi_indicator, String
    attribute :primary_fullname, String
    attribute :employee_fullname, String
    attribute :primary_identifier, String
    attribute :employee_fullname, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :employer_name, String
    attribute :employer_email, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :open_enrollment_end_on, Date
    attribute :start_on, Date
    attribute :legal_name, String
    attribute :benefit_group_package_name, String
    attribute :metal_leval, String
    attribute :carrier, String
    attribute :generate_url, String
    attribute :reference_plan, Object
    attribute :family_contribution, String
    attribute :data, Hash
    attribute :coverage_end_on, Date
    attribute :coverage_start_on, Date
    attribute :to, String
    attribute :plan, PdfTemplates::Plan
    attribute :benefit_group_assignments, Hash
    attribute :plan_year, PdfTemplates::PlanYear
    attribute :aasm_state, String
    attribute :employee_email, String
    attribute :sep, PdfTemplates::SpecialEnrollmentPeriod
    attribute :enrollment, PdfTemplates::Enrollment
    attribute :employee, PdfTemplates::EmployeeNotice

    def shop?
      return true
    end

    def broker?
      return false
    end

    def employee_notice?
      false
    end

    def general_agency?
      false
    end

  end
end
