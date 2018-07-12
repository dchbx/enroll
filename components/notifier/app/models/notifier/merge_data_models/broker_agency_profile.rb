module Notifier
  class MergeDataModels::BrokerAgencyProfile

    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address

    attribute :broker_agency_name, String
    attribute :termination_date, String
    attribute :assignment_date, String
    attribute :employer_name, String
    attribute :employer_poc_firstname, String
    attribute :employer_poc_lastname, String
    attribute :employer_poc_phone, String
    attribute :employer_poc_email, String

    def self.stubbed_object
      notice = Notifier::MergeDataModels::BrokerAgencyProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        broker_agency_name: 'Best Brokers LLC',
        assignment_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        termination_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        employer_name: 'North America Football Federation',
        employer_poc_firstname: 'David',
        employer_poc_lastname: 'Samules',
        employer_poc_phone: '703-373-1007',
        employer_poc_email: 'david.sam@naff.llc'
        })
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice
    end

    def collections
      []
    end

    def conditions
      []
    end
  end
end