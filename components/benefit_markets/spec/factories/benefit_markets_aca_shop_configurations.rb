# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_aca_shop_configuration, class: 'BenefitMarkets::Configurations::AcaShopConfiguration' do
    ee_ct_max { 50 }
    employee_participation_ratio_min { 0.666 }
    ee_non_owner_ct_min { 1 }
    er_contrib_pct_min { 75 }
    binder_due_dom { 10 }
    erlst_e_prior_eod { -30 }
    ltst_e_aft_eod { 30 }
    ltst_e_aft_ee_roster_cod { 30 }
    retroactve_covg_term_max_dys { -60 }
    ben_per_min_year { 1 }
    ben_per_max_year { 1 }
    oe_start_month { 1 }
    oe_end_month { 10 }
    oe_min_dys { 5 }
    oe_grce_min_dys { 5 }
    oe_min_adv_dys { 5 }
    oe_max_months { 2 }
    cobra_epm { 6 }
    gf_new_enrollment_trans { 16 }
    gf_update_trans_dow { "friday" }
    use_simple_er_cal_model { true }
    offerings_constrained_to_service_areas { false }
    trans_er_immed { false }
    trans_scheduled_er { true }
    er_transmission_dom { 16 }
    enforce_er_attest { false }
    stan_indus_class { false }
    carrier_filters_enabled { false }

    after :build do |configuration|
      configuration.initial_application_configuration = build :benefit_markets_aca_shop_initial_application_configuration, configuration: configuration
      configuration.renewal_application_configuration = build :benefit_markets_aca_shop_renewal_application_configuration, configuration: configuration
    end
  end
end
