module Notifier
  class MergeDataModels::Address
    include Virtus.model

    attribute :street_1, String
    attribute :street_2, String
    attribute :city, String
    attribute :state, String
    attribute :zip, String

    def self.stubbed_object
      Notifier::MergeDataModels::Address.new({
        street_1: '330 Montague City Road',
        street_2: 'Suite 200',
        city: 'Turners Falls',
        state: 'MA',
        zip: '01373'
      })
    end
  end
end
