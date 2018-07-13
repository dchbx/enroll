module BenefitMarkets
  module Forms
    class AcaShopConfiguration
      extend  ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations
      include Virtus.model
      
      attribute :ee_ct_max, Integer
      attribute :ee_ratio_min, Float
      attribute :ee_non_owner_ct_min, Integer
      attribute :er_contrib_pct_min, Integer
      attribute :binder_due_dom, Integer
      attribute :erlst_e_prior_eod, Integer
      attribute :ltst_e_aft_eod, Integer
      attribute :ltst_e_aft_ee_roster_cod, Integer
      attribute :retroactve_covg_term_max_dys, Integer
      attribute :ben_per_min_year, Integer
      attribute :ben_per_max_year, Integer
      attribute :oe_start_month, Integer
      attribute :oe_end_month, Integer
      attribute :oe_min_dys, Integer
      attribute :oe_grce_min_dys, Integer
      attribute :oe_min_adv_dys, Integer
      attribute :oe_max_months, Integer
      attribute :cobra_epm, Integer
      attribute :gf_new_enrollment_trans, Integer
      attribute :gf_update_trans_dow, String
      attribute :use_simple_er_cal_model, Boolean
      attribute :offerings_constrained_to_service_areas, Boolean
      attribute :trans_er_immed, Boolean
      attribute :trans_scheduled_er, Boolean
      attribute :er_transmission_dom, Integer
      attribute :enforce_er_attest, Boolean
      attribute :stan_indus_class, Boolean
      attribute :carrier_filters_enabled, Boolean
      attribute :rating_areas, Array
      attribute :initial_application_configuration, BenefitMarkets::Forms::AcaShopInitialApplicationConfiguration
      attribute :renewal_application_configuration, BenefitMarkets::Forms::AcaShopRenewalApplicationConfiguration
      
    end
  end
end