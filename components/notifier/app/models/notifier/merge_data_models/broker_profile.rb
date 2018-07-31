module Notifier
  class MergeDataModels::BrokerProfile

    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address

    attribute :email, String
    attribute :broker_agency_name, String
    attribute :assignment_date, String
    attribute :termination_date, Date
    attribute :employer_name, String
    attribute :employer_poc_firstname, String
    attribute :employer_poc_lastname, String

    def self.stubbed_object
      notice = Notifier::MergeDataModels::BrokerProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        broker_agency_name: 'Best Brokers LLC',
        email: 'john.whitmore@yopmail.com',
        assignment_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y') ,
        termination_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y') ,
        employer_name: 'North America Football Federation',
        employer_poc_firstname: 'David',
        employer_poc_lastname: 'Samules'
        })
      notice.mailing_address = Notifier::MergeDataModels::Address.new
      notice
    end

    def collections
      []
    end

    def conditions
      []
    end

    def primary_address
      mailing_address
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
      true
    end
  end
end