FactoryGirl.define do
  factory :benefit_markets_aca_initial_individual_configuration, class: 'BenefitMarkets::Configurations::AcaInitialIndividualConfiguration' do

    pub_due_dom   5
    erlst_strt_prior_eff_months  -3
    appeal_per_aft_app_denial_dys 30
    quiet_per_end 28
    inelig_per_aft_app_denial_dys 90
  end
end
