module Notifier
  class MergeDataModels::EmployeeProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :enrollment_plan_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :employer_name, String
    # attribute :coverage_begin_date, Date
    attribute :dependents_name, String
    attribute :dependent_termination_date, String
    attribute :broker, MergeDataModels::Broker
    attribute :email, String
    attribute :date_of_hire, String
    attribute :termination_of_employment, String
    attribute :coverage_terminated_on, String
    attribute :coverage_terminated_on_plus_30_days, String
    attribute :earliest_coverage_begin_date, String
    attribute :ivl_oe_start_date, Date
    attribute :ivl_oe_end_date, Date
    attribute :new_hire_oe_start_date, String
    attribute :new_hire_oe_end_date, String
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollment, MergeDataModels::Enrollment
    attribute :dental_enrollment, MergeDataModels::Enrollment
    attribute :benefit_application, MergeDataModels::BenefitApplication
    attribute :census_employee, MergeDataModels::CensusEmployee
    attribute :special_enrollment_period, MergeDataModels::SpecialEnrollmentPeriod

    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployeeProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        enrollment_plan_name: 'Aetna GOLD',
        employer_name: 'Whitmore, Inc',
        email: 'johnwhitmore@yahoo.com',
        ivl_oe_start_date: Settings.aca.individual_market.upcoming_open_enrollment.start_on,
        ivl_oe_end_date: Settings.aca.individual_market.upcoming_open_enrollment.end_on,
        # coverage_begin_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        date_of_hire: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        termination_of_employment: TimeKeeper.date_of_record.prev_day.strftime('%m/%d/%Y'),
        coverage_terminated_on: TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y'),
        coverage_terminated_on_plus_30_days: (TimeKeeper.date_of_record + 30.days).strftime('%m/%d/%Y'),
        earliest_coverage_begin_date: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y'),
        new_hire_oe_end_date: (TimeKeeper.date_of_record + 30.days).strftime('%m/%d/%Y'),
        new_hire_oe_start_date: TimeKeeper.date_of_record.strftime('%m,/%d/%Y')
      })
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice.enrollment = Notifier::MergeDataModels::Enrollment.stubbed_object
      notice.dental_enrollment = Notifier::MergeDataModels::Enrollment.stubbed_object_dental
      notice.benefit_application = Notifier::MergeDataModels::BenefitApplication.stubbed_object
      notice.census_employee = Notifier::MergeDataModels::CensusEmployee.stubbed_object
      notice.special_enrollment_period = Notifier::MergeDataModels::SpecialEnrollmentPeriod.stubbed_object
      notice
    end

    def collections
      []
    end

    def conditions
      %w[broker_present? has_parent_enrollment? future_sep?
         has_multiple_enrolled_enrollments? has_health_enrolled_enrollment? has_dental_enrolled_enrollment?
         census_employee_health_and_dental_enrollment? census_employee_health_enrollment? census_employee_dental_enrollment?]
    end

    def has_parent_enrollment?
      enrollment.waiver_plan_name.present?
    end

    def future_sep?
      Date.strptime(special_enrollment_period.event_on, '%m/%d/%Y').future?
    end

    def census_employee_health_enrollment?
      self.census_employee.latest_terminated_health_enrollment_plan_name.present?
    end

    def census_employee_dental_enrollment?
      self.census_employee.latest_terminated_dental_enrollment_plan_name.present?
    end

    def census_employee_health_and_dental_enrollment?
      census_employee_health_enrollment? && census_employee_dental_enrollment?
    end

    def has_multiple_enrolled_enrollments?
      has_health_enrolled_enrollment? && has_dental_enrolled_enrollment?
    end

    def has_health_enrolled_enrollment?
      enrollment && enrollment.plan_name.present?
    end

    def has_dental_enrolled_enrollment?
      dental_enrollment && dental_enrollment.plan_name.present?
    end

    def primary_address
      mailing_address
    end

    def broker_present?
      self.broker.present?
    end

    def employee_notice?
      true
    end

    def general_agency?
      false
    end

    def broker?
      false
    end

    def shop?
      true
    end
  end
end
