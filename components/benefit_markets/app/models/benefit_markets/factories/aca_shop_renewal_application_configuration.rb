module BenefitMarkets
  module Factories
    class AcaShopRenewalApplicationConfiguration
      def self.call(erlst_strt_prior_eff_months:, force_pub_dom:, montly_oe_end:, oe_min_dys:, pub_due_dom:, quiet_per_end:)
        BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration.new erlst_strt_prior_eff_months: erlst_strt_prior_eff_months,
          force_pub_dom: force_pub_dom,
          montly_oe_end: montly_oe_end,
          oe_min_dys: oe_min_dys,
          pub_due_dom: pub_due_dom,
          quiet_per_end: quiet_per_end
      end
    end
  end
end