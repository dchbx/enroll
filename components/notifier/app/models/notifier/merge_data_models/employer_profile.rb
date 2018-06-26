module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    DATE_ELEMENTS = %w(current_py_start_on current_py_end_on renewal_py_start_on renewal_py_end_on)

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    # attribute :primary_identifier, String
    # attribute :mpi_indicator, String
    attribute :email, String
    attribute :application_date, String
    attribute :invoice_month, String
    attribute :account_number, String
    attribute :invoice_number, String
    attribute :invoice_date, String
    attribute :coverage_month, String
    attribute :total_amount_due, String
    attribute :date_due, String
    attribute :employer_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::Broker
    # attribute :to, String
    # attribute :plan, MergeDataModels::Plan
    attribute :plan_year, MergeDataModels::PlanYear
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollment, MergeDataModels::Enrollment

    attribute :offered_products, Array[MergeDataModels::OfferedProduct] # Grouping of employee coverages by plan

    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployerProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        email: 'johnwhitmore@gmail.com',
        application_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        invoice_month: TimeKeeper.date_of_record.next_month.strftime('%B'),
        employer_name: 'North America Football Federation',
        account_number: '1056530',
        invoice_number: '1056530072017',
        invoice_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y"),
        coverage_month: TimeKeeper.date_of_record.next_month.strftime("%m/%Y"),
        total_amount_due: '$1523.25',
        date_due: (TimeKeeper.date_of_record + 10.days).strftime("%m/%d/%Y")


      })

      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.plan_year = Notifier::MergeDataModels::PlanYear.stubbed_object
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.enrollment = Notifier::MergeDataModels::Enrollment.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice.offered_products = [ Notifier::MergeDataModels::OfferedProduct.stubbed_object ]
      notice
    end

    def collections
      %w{addresses offered_products}
    end

    def conditions
      %w{broker_present?}
    end

    def primary_address
      mailing_address
    end

    def broker_present?
      self.broker.present?
    end

    def shop?
      true
    end

    def employee_notice?
      false
    end

    def general_agency?
      false
    end

    def broker?
      false
    end
  end
end
