module BenefitMarkets
  module Configurations
    # AcaShopConfiguration settings
    class AcaShopConfiguration < BenefitMarkets::Configurations::Configuration

      TRANSMIT_DAYS = %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
      embeds_one :initial_application_configuration,  class_name: "BenefitMarkets::Configurations::AcaShopInitialApplicationConfiguration",
        autobuild: true
      embeds_one :renewal_application_configuration,  class_name: "BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration",
        autobuild: true

      field :ee_ct_max,           as: :employee_count_max, type: Integer, default: 50
      field :ee_ratio_min,        as: :employee_participation_ratio_min, type: Float, default: 0.75
      field :ee_non_owner_ct_min, as: :employee_non_owner_count_min, type: Integer, default: 1
      field :er_contrib_pct_min,  as: :employer_contribution_pct_min, type: Integer, default: 75
      field :binder_due_dom, as: :binder_payment_due_day_of_month, type: Integer
      field :erlst_e_prior_eod, as: :earliest_enroll_prior_effective_on_days, type: Integer, default: -30
      field :ltst_e_aft_eod, as: :latest_enroll_after_effective_on_days, type: Integer, default: 30
      field :ltst_e_aft_ee_roster_cod, as: :latest_enroll_after_ee_roster_correction_on_days, type: Integer, default: 30
      field :retroactve_covg_term_max_dys, as: :retroactive_coverage_termination_max_days, type: Integer, default: -60
      field :ben_per_min_year, as: :benefit_period_min_year, type: Integer, default: 1
      field :ben_per_max_year, as: :benefit_period_max_year, type: Integer, default: 1
      field :oe_start_month, as: :open_enrollment_start_on_montly, type: Integer, default: 1
      field :oe_end_month, as: :open_enrollment_end_on_montly, type: Integer, default: 20
      field :oe_min_dys, as: :open_enrollment_days_min, type: Integer, default: 5
      field :oe_grce_min_dys, as: :open_enrollment_grace_period_length_days_min, type: Integer, default: 5
      field :oe_min_adv_dys, as: :open_enrollment_adv_days_min, type: Integer, default: 5
      field :oe_max_months, as: :open_enrollment_months_max, type: Integer, default: 2
      field :cobra_epm, as: :cobra_enrollment_period_month, type: Integer, default: 6
      field :gf_new_enrollment_trans, as: :group_file_new_enrollment_transmit_on, type: Integer, default: 16
      field :gf_update_trans_dow, as: :group_file_update_transmit_day_of_week, type: String, default: "friday"
      field :use_simple_er_cal_model, as: :use_simple_employer_calculation_model, type: Boolean, default: false
      field :offerings_constrained_to_service_areas, type: Boolean, default: false
      field :trans_er_immed, as: :transmit_employers_immediately, type: Boolean, default: false
      field :trans_scheduled_er, as: :transmit_scheduled_employers, type: Boolean, default: true
      field :er_transmission_dom, as: :employer_transmission_day_of_month, type: Integer, default: 16
      field :enforce_er_attest, as: :enforce_employer_attestation, type: Boolean, default: true
      field :stan_indus_class, as: :standard_industrial_classification, type: Boolean, default: false
      field :carrier_filters_enabled, type: Boolean, default: false

      validates_presence_of :ben_per_max_year, :ben_per_min_year, :binder_due_dom, :carrier_filters_enabled, :cobra_epm, :ee_ct_max, :ee_non_owner_ct_min, :ee_ratio_min, :enforce_er_attest, :er_contrib_pct_min, :er_transmission_dom, :erlst_e_prior_eod, :gf_new_enrollment_trans, :gf_update_trans_dow, :initial_application_configuration, :ltst_e_aft_ee_roster_cod, :ltst_e_aft_eod, :oe_end_month, :oe_grce_min_dys, :oe_max_months, :oe_min_adv_dys, :oe_min_dys, :oe_start_month, :offerings_constrained_to_service_areas, :renewal_application_configuration, :retroactve_covg_term_max_dys, :stan_indus_class, :trans_er_immed, :trans_scheduled_er, :use_simple_er_cal_model
    end
  end
end
