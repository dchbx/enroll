Given("shop health plans exist for both last and this year") do
  year = (Date.today - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).year
  plan = FactoryGirl.create :plan, :with_premium_tables, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000, is_sole_source: false
  plan2 = FactoryGirl.create :plan, :with_premium_tables, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id, is_sole_source: false
  sole_source_plan = FactoryGirl.create :plan, :with_rating_factors, :with_premium_tables, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id, is_vertical: false, is_horizontal: false, is_sole_source: true
  sole_source_plan_two = FactoryGirl.create :plan, :with_rating_factors, :with_premium_tables, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id, is_vertical: false, is_horizontal: false, is_sole_source: true

end

Given("vertical and horizontal plan choices are offered") do
  allow(Config::AcaHelper).to receive(:offers_single_carrier?).and_return(true)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_single_carrier?).and_return(true)
  allow(Config::AcaHelper).to receive(:offers_metal_level?).and_return(true)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_metal_level?).and_return(true)
  allow(Config::AcaHelper).to receive(:offers_sole_source?).and_return(false)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_sole_source?).and_return(false)
end

Given('only sole source plans are offered') do
  allow(Config::AcaHelper).to receive(:offers_single_carrier?).and_return(false)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_single_carrier?).and_return(false)
  allow(Config::AcaHelper).to receive(:offers_metal_level?).and_return(false)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_metal_level?).and_return(false)
  allow(Config::AcaHelper).to receive(:offers_sole_source?).and_return(true)
  allow_any_instance_of(Config::AcaHelper).to receive(:offers_sole_source?).and_return(true)
end
