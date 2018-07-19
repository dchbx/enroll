FactoryGirl.define do
  factory :benefit_markets_aca_shop_initial_application_configuration, class: 'BenefitMarkets::Configurations::AcaShopInitialApplicationConfiguration' do
    pub_due_dom 6
    erlst_strt_prior_eff_months -3
    appeal_per_aft_app_denial_dys 30
    quiet_per_end 28
    inelig_per_aft_app_denial_dys 90
  end
end
