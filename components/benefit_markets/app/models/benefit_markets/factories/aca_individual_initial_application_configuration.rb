module BenefitMarkets
  module Factories
    class AcaIndividualInitialApplicationConfiguration
      def self.call(appeal_per_aft_app_denial_dys:, erlst_strt_prior_eff_months:, inelig_per_aft_app_denial_dys:, pub_due_dom:, quiet_per_end:)
        BenefitMarkets::Configurations::AcaIndividualInitialApplicationConfiguration.new appeal_per_aft_app_denial_dys: appeal_per_aft_app_denial_dys,
          erlst_strt_prior_eff_months: erlst_strt_prior_eff_months,
          inelig_per_aft_app_denial_dys: inelig_per_aft_app_denial_dys,
          pub_due_dom: pub_due_dom,
          quiet_per_end: quiet_per_end
      end
    end
  end
end