# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_aca_shop_renewal_application_configuration, class: 'BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration' do
    erlst_strt_prior_eff_months { -2 }
    montly_oe_end { 13 }
    pub_due_dom { 10 }
    force_pub_dom { 11 }
    oe_min_dys { 3 }
    quiet_per_end { 15 }
  end
end
