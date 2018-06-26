module Notifier
  class Builders::EmployerProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment
    include Notifier::Builders::OfferedProduct
    include ActionView::Helpers::NumberHelper
    include Config::ContactCenterHelper
    include Config::SiteHelper

    attr_accessor :employer_profile, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::EmployerProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.offered_products = Notifier::MergeDataModels::OfferedProduct.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employer_profile = resource
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
      office_address = employer_profile.organization.primary_office_location.address
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

    def notice_date
      merge_model.notice_date = format_date(TimeKeeper.date_of_record)
    end

    def employer_name
      merge_model.employer_name = employer_profile.legal_name
    end

    def email
      merge_model.email = employer_profile.staff_roles.first.work_email_or_best
    end

    def first_name
      if employer_profile.staff_roles.present?
        merge_model.first_name = employer_profile.staff_roles.first.first_name
      end
    end

    def last_name
      if employer_profile.staff_roles.present?
        merge_model.last_name = employer_profile.staff_roles.first.last_name
      end
    end

    def invoice_month
      merge_model.invoice_month = TimeKeeper.date_of_record.next_month.strftime('%B')
    end

    def account_number
      merge_model.account_number = employer_profile.organization.hbx_id
    end

    def invoice_number
      merge_model.invoice_number = "#{employer_profile.organization.hbx_id}#{DateTime.now.next_month.strftime('%m%Y')}"
    end

    def invoice_date
      merge_model.invoice_date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    end

    def coverage_month
      merge_model.coverage_month = TimeKeeper.date_of_record.next_month.strftime("%m/%Y")
    end

    def total_amount_due
      merge_model.total_amount_due = number_to_currency(employer_profile.plan_years.enrolled.first.hbx_enrollments.map(&:total_premium).sum)
    end

    def date_due
      merge_model.date_due = PlanYear.calculate_open_enrollment_date(TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].strftime("%m/%d/%Y")
    end
  end
end
