module Notifier
  class MergeDataModels::Broker
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_first_name, String
    attribute :primary_last_name, String
    attribute :assignment_date, Date
    attribute :termination_date, Date
    attribute :organization, String
    attribute :address, MergeDataModels::Address
    attribute :phone, String
    attribute :email, String
    attribute :web_address, String


    def self.stubbed_object
      Notifier::MergeDataModels::Broker.new({
        primary_fullname: 'Count Olaf',
        primary_first_name: 'Count',
        primary_last_name: 'Olaf',
        organization: 'Best Brokers LLC',
        phone: '703-303-1007',
        email: 'count.olaf@bestbrokers.llc',
        web_address: 'http://bestbrokers.llc',
        assignment_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        termination_date: TimeKeeper.date_of_record.prev_day.strftime('%m/%d/%Y')
      })
    end
  end
end
