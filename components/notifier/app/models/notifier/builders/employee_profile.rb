module Notifier
  class Builders::EmployeeProfile

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment

    attr_accessor :employee_role, :merge_model, :payload, :event_name, :sep_id
    attr_accessor :qle_title, :qle_event_on, :qle_reporting_deadline

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.census_employee = Notifier::MergeDataModels::CensusEmployee.new
      data_object.special_enrollment_period = Notifier::MergeDataModels::SpecialEnrollmentPeriod.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employee_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def first_name
      merge_model.first_name = employee_role.person.first_name if employee_role.present?
    end

    def last_name
      merge_model.last_name = employee_role.person.last_name if employee_role.present?
    end

    def append_contact_details
      mailing_address = employee_role.person.mailing_address
      if mailing_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: mailing_address.address_1,
          street_2: mailing_address.address_2,
          city: mailing_address.city,
          state: mailing_address.state,
          zip: mailing_address.zip
          })
      end
    end

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = Settings.aca.individual_market.upcoming_open_enrollment.start_on
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = Settings.aca.individual_market.upcoming_open_enrollment.end_on
    end

    def email
      merge_model.email = employee_role.person.work_email_or_best if employee_role.present?
    end

    def employer_name
      merge_model.employer_name = employee_role.employer_profile.legal_name
    end

    def enrollment
      return @enrollment if defined? @enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.find(payload['event_object_id'])
      elsif event_name == "employee_notice_for_employee_terminated_from_roster"
        @enrollment = latest_terminated_health_enrollment if latest_terminated_health_enrollment.present?
      end
    end

    def enrollment_coverage_end_on
      return if enrollment.blank?
      if event_name == "employee_notice_for_employee_terminated_from_roster"
        merge_model.enrollment.coverage_end_on = format_date(census_employee_record.employment_terminated_on.end_of_month)
      else
        merge_model.enrollment.coverage_end_on = format_date(enrollment.terminated_on)
      end
    end

    def enrollment_coverage_start_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_plan_name
      if enrollment.present?
        merge_model.enrollment.plan_name = enrollment.plan.name
      end
    end

    def enrollment_employee_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employee_responsible_amount = number_to_currency(enrollment.total_employee_cost, precision: 2)
    end

    def enrollment_employer_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employer_responsible_amount = number_to_currency(enrollment.total_employer_contribution, precision: 2)
    end

    def census_employee_record
      employee_role.census_employee
    end

    def date_of_hire
      merge_model.date_of_hire = format_date(census_employee_record.hired_on)
    end

    def termination_of_employment
      merge_model.termination_of_employment = format_date(census_employee_record.employment_terminated_on)
    end

    def coverage_terminated_on
      merge_model.coverage_terminated_on = format_date(census_employee_record.coverage_terminated_on)
    end

    def earliest_coverage_begin_date
      merge_model.earliest_coverage_begin_date = format_date census_employee_record.coverage_effective_on
    end

    def new_hire_oe_start_date
      merge_model.new_hire_oe_start_date = format_date(census_employee_record.new_hire_enrollment_period.min)
    end

    def new_hire_oe_end_date
      merge_model.new_hire_oe_end_date = format_date(census_employee_record.new_hire_enrollment_period.max)
    end

    def census_employee_health_enrollment?
      merge_model.census_employee.latest_terminated_health_enrollment_plan_name.present?
    end

    def census_employee_dental_enrollment?
      merge_model.census_employee.latest_terminated_dental_enrollment_plan_name.present?
    end

    def census_employee_health_and_dental_enrollment?
      census_employee_health_enrollment? && census_employee_dental_enrollment?
    end

    def latest_terminated_health_enrollment
      census_employee_record.active_benefit_group_assignment.hbx_enrollments.select{ |en| en.coverage_kind == "health" }.first
    end

    def latest_terminated_dental_enrollment
      census_employee_record.active_benefit_group_assignment.hbx_enrollments.select{ |en| en.coverage_kind == "dental" }.first
    end

    def census_employee_latest_terminated_health_enrollment_plan_name
      if latest_terminated_health_enrollment.present?
        merge_model.census_employee.latest_terminated_health_enrollment_plan_name = latest_terminated_health_enrollment.plan.name
      end
    end

    def census_employee_latest_terminated_dental_enrollment_plan_name
      if latest_terminated_dental_enrollment.present?
        merge_model.census_employee.latest_terminated_dental_enrollment_plan_name = latest_terminated_dental_enrollment.plan.name
      end
    end

    def employer_profile
      employee_role.employer_profile
    end

    def dependents_name
      names = []
      payload["notice_params"]["dep_hbx_ids"].each do |dep_id|
        names << Person.where(hbx_id: dep_id).first.full_name
      end
      merge_model.dependents_name = names.join(", ")
    end

    def dependent_termination_date
      merge_model.dependent_termination_date = format_date(TimeKeeper.date_of_record.end_of_month)
    end
    
    # Using same merge model for special enrollment period and qualifying life event kind.
    def special_enrollment_period
      return @special_enrollment_period if defined? @special_enrollment_period
      if payload['event_object_kind'].constantize == SpecialEnrollmentPeriod
        @special_enrollment_period = employee_role.person.primary_family.special_enrollment_periods.find(payload['event_object_id'])
      elsif payload['event_object_kind'].constantize == QualifyingLifeEventKind
        @special_enrollment_period = QualifyingLifeEventKind.find(payload['event_object_id'])
      else
        @special_enrollment_period = employee_role.person.primary_family.current_sep
      end
    end

    def special_enrollment_period_event_on
      event_on = special_enrollment_period.nil? ? payload['notice_params']['qle_event_on'] : special_enrollment_period.event_on
      merge_model.special_enrollment_period.event_on = event_on
    end

    def special_enrollment_period_title
      merge_model.special_enrollment_period.title = special_enrollment_period.nil? ? payload['notice_params']['qle_title'] : special_enrollment_period.title
    end

    def special_enrollment_period_qle_reported_on
      merge_model.special_enrollment_period.qle_reported_on = (special_enrollment_period.present? && special_enrollment_period.qle_on.present?) ? format_date(special_enrollment_period.qle_on) : format_date(TimeKeeper.date_of_record)
    end

    def special_enrollment_period_start_on
      if special_enrollment_period.present? && special_enrollment_period.start_on.present?
        merge_model.special_enrollment_period.start_on = format_date(special_enrollment_period.start_on)
      end
    end

    def special_enrollment_period_end_on
      merge_model.special_enrollment_period.end_on = format_date(special_enrollment_period.end_on)
    end

    def special_enrollment_period_submitted_at
      merge_model.special_enrollment_period.submitted_at = format_date(special_enrollment_period.submitted_at) if special_enrollment_period.submitted_at.present?
    end

    def special_enrollment_period_reporting_deadline
      deadline = payload['notice_params']['qle_reporting_deadline']
      merge_model.special_enrollment_period.reporting_deadline = deadline
    end

    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end
  end
end
