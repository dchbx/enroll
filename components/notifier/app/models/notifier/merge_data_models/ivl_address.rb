module Notifier
  class MergeDataModels::IvlAddress
    include Virtus.model

    attribute :street_1, String
    attribute :street_2, String
    attribute :city, String
    attribute :state, String
    attribute :zip, String

    def self.stubbed_object
      Notifier::MergeDataModels::IvlAddress.new({
        street_1: 'DC Health',
        street_2: 'PO Box 44018',
        city: 'Washington',
        state: 'DC',
        zip: '20026'
      })
    end
  end
end