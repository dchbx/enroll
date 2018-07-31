module BenefitMarkets
  module Factories
    class AcaShopConfiguration
      def self.build
        BenefitMarkets::Configurations::AcaShopConfiguration.new( 
          initial_application_configuration: BenefitMarkets::Configurations::AcaShopInitialApplicationConfiguration.new,
          renewal_application_configuration: BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration.new
        )
      end
      
      def self.call(ben_per_max_year:, 
                    ben_per_min_year:,
                    binder_due_dom:,
                    carrier_filters_enabled:,
                    cobra_epm:,
                    ee_ct_max:,
                    ee_non_owner_ct_min:,
                    ee_ratio_min:,
                    enforce_er_attest:,
                    er_contrib_pct_min:,
                    er_transmission_dom:,
                    erlst_e_prior_eod:,
                    gf_new_enrollment_trans:,
                    gf_update_trans_dow:,
                    initial_application_configuration:,
                    ltst_e_aft_ee_roster_cod:,
                    ltst_e_aft_eod:,
                    oe_end_month:,
                    oe_grce_min_dys:,
                    oe_max_months:,
                    oe_min_adv_dys:,
                    oe_min_dys:,
                    oe_start_month:,
                    offerings_constrained_to_service_areas:,
                    rating_areas:,
                    renewal_application_configuration:,
                    retroactve_covg_term_max_dys:,
                    stan_indus_class:,
                    trans_er_immed:,
                    trans_scheduled_er:,
                    use_simple_er_cal_model:)
        BenefitMarkets::Configurations::AcaShopConfiguration.new ben_per_max_year: ben_per_max_year,
          ben_per_min_year: ben_per_min_year,
          binder_due_dom: binder_due_dom,
          carrier_filters_enabled: carrier_filters_enabled,
          cobra_epm: cobra_epm,
          ee_ct_max: ee_ct_max,
          ee_non_owner_ct_min: ee_non_owner_ct_min,
          ee_ratio_min: ee_non_owner_ct_min,
          enforce_er_attest: enforce_er_attest,
          er_contrib_pct_min: er_contrib_pct_min,
          er_transmission_dom: er_transmission_dom,
          erlst_e_prior_eod: erlst_e_prior_eod,
          gf_new_enrollment_trans: gf_new_enrollment_trans,
          gf_update_trans_dow: gf_update_trans_dow,
          initial_application_configuration: initial_application_configuration,
          ltst_e_aft_ee_roster_cod: ltst_e_aft_ee_roster_cod,
          ltst_e_aft_eod: ltst_e_aft_eod,
          oe_end_month: oe_end_month,
          oe_grce_min_dys: oe_grce_min_dys,
          oe_max_months: oe_max_months,
          oe_min_adv_dys: oe_min_adv_dys,
          oe_min_dys: oe_min_dys,
          oe_start_month: oe_start_month,
          offerings_constrained_to_service_areas: offerings_constrained_to_service_areas,
          rating_areas: rating_areas,
          renewal_application_configuration: renewal_application_configuration,
          retroactve_covg_term_max_dys: retroactve_covg_term_max_dys,
          stan_indus_class: stan_indus_class,
          trans_er_immed: trans_er_immed,
          trans_scheduled_er: trans_scheduled_er,
          use_simple_er_cal_model: use_simple_er_cal_model
      end
    end
  end
end