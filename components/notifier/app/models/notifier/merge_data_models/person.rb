module Notifier
  class MergeDataModels::Person
    include Virtus.model

    attribute :first_name, String
    attribute :last_name, String

    def self.stubbed_object
      Notifier::MergeDataModels::Person.new({
        first_name: "John",
        last_name: "Adams"
        })
    end
  end
end
