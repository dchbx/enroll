module BenefitMarkets
  module Forms
    class AcaShopRenewalApplicationConfiguration
      extend  ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations
      include Virtus.model

      attribute :erlst_strt_prior_eff_months, Integer
      attribute :montly_oe_end, Integer
      attribute :pub_due_dom, Integer
      attribute :force_pub_dom, Integer
      attribute :oe_min_dys, Integer
      attribute :quiet_per_end, Integer
    end
  end
end