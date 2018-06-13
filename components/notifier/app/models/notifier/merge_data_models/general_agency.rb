module Notifier
  class MergeDataModels::GeneralAgency

    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address

    attribute :email, String
    attribute :broker, MergeDataModels::Broker
    attribute :legal_name, String
    attribute :assignment_date, Date
    attribute :employer_name, String
    attribute :employer_poc_firstname, String
    attribute :employer_poc_lastname, String


    def self.stubbed_object
      notice = Notifier::MergeDataModels::GeneralAgency.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'Johnny',
        last_name: 'Pepper',
        email: 'johnnypepper@ypomail.com',
        legal_name: 'Best General Agency LLC',
        assignment_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y') ,
        employer_name: 'North America Football Federation',
        employer_poc_firstname: 'David',
        employer_poc_lastname: 'Samules'
        })
      notice.broker = Notifier::MergeDataModels::Broker.stubbed_object
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice
    end

    def collections
      %w{addresses}
    end

    def conditions
      []
    end

    def shop?
      true
    end

    def employee_notice?
      false
    end
  end
end