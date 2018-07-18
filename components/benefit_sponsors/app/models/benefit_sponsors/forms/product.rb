module BenefitSponsors
  module Forms
    class Product

      include ActiveModel::Validations
      include Virtus.model

      attribute :title, String
      attribute :issuer_name, String
      attribute :plan_kind, String
      attribute :metal_level_kind, String
      attribute :network_information, String

    end
  end
end
