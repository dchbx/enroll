module Notifier
  class Builders::EmployerProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::BenefitApplication
    include Notifier::Builders::BenefitPackage
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment
    include Notifier::Builders::OfferedProduct
    include ActionView::Helpers::NumberHelper
    include Config::ContactCenterHelper
    include Config::SiteHelper

    attr_accessor :employer_profile, :merge_model, :payload, :event_name

    def initialize
      data_object = Notifier::MergeDataModels::EmployerProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.benefit_application = Notifier::MergeDataModels::BenefitApplication.new
      data_object.benefit_packages = Notifier::MergeDataModels::BenefitPackage.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.offered_products = Notifier::MergeDataModels::OfferedProduct.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employer_profile ||= resource
    end

    def append_contact_details
      first_name
      last_name
      addresses
    end

    def addresses
      merge_model.addresses = primary_address
    end

    def primary_address
      office_address = employer_profile.primary_office_location.address
      if office_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: office_address.address_1,
          street_2: office_address.address_2,
          city: office_address.city,
          state: office_address.state,
          zip: office_address.zip
          })
      end
    end

    def current_sys_date
      @current_sys_date ||= TimeKeeper.date_of_record
    end

    def notice_date
      merge_model.notice_date = format_date(current_sys_date)
    end

    def notice_date_plus_31_days
      merge_model.notice_date_plus_31_days = format_date(current_sys_date + 31.days)
    end

    def employer_name
      merge_model.employer_name = employer_profile.legal_name
    end

    def employer_staff_role
      return nil unless employer_profile.staff_roles

      @employer_staff_role ||= employer_profile.staff_roles.first
    end

    def email
      return nil unless employer_staff_role

      merge_model.email = employer_staff_role.work_email_or_best
    end

    def first_name
      return nil unless employer_staff_role

      merge_model.first_name = employer_staff_role.first_name
    end

    def last_name
      return nil unless employer_staff_role

      merge_model.last_name = employer_staff_role.last_name
    end

    def invoice_month
      merge_model.invoice_month = current_sys_date.next_month.strftime('%B')
    end

    def account_number
      merge_model.account_number = employer_profile.organization.hbx_id
    end

    def invoice_number
      merge_model.invoice_number = "#{employer_profile.organization.hbx_id}#{DateTime.now.next_month.strftime('%m%Y')}"
    end

    def invoice_date
      merge_model.invoice_date = current_sys_date.strftime("%m/%d/%Y")
    end

    def active_benefit_sponsorship
      employer_profile.active_benefit_sponsorship
    end

    def coverage_month
      merge_model.coverage_month = current_sys_date.next_month.strftime("%m/%Y")
    end

    def submitted_benefit_application
      submitted_states = BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES - [:termination_pending, :enrollment_open]
      active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => submitted_states).max_by(&:created_at)
    end

    def total_amount_due
      merge_model.total_amount_due = number_to_currency(submitted_benefit_application.enrollments_till_given_effective_on(current_sys_date.next_month.beginning_of_month).reject{|enr| enr.aasm_state == "inactive"}.map(&:total_premium).sum)
    end

    def date_due
      schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      merge_model.date_due = schedular.calculate_open_enrollment_date(false, current_sys_date.next_month.beginning_of_month)[:binder_payment_due_date].strftime("%m/%d/%Y")
    end
  end
end
