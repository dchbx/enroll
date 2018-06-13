module Notifier
  class MergeDataModels::HealthBenefitExchange
    include Virtus.model

    attribute :name, String
    attribute :url, String
    attribute :phone, String
    attribute :fax, String
    attribute :email, String
    attribute :address, MergeDataModels::Address
  end
end
