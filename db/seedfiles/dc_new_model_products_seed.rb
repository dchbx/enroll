site = BenefitSponsors::Site.all.first
if site.blank?
  site = BenefitSponsors::Site.new(site_key: "#{Settings.site.key}")
end

# Clear the current models
puts "Clearing model instances..."
BenefitMarkets::BenefitMarket.all.delete
BenefitMarkets::BenefitMarketCatalog.all.delete
BenefitMarkets::Products::ProductPackage.all.delete
BenefitMarkets::Products::HealthProducts::HealthProduct.all.delete
BenefitSponsors::Organizations::Organization.where(:"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").delete

puts "Loading carrier profiles..."
Organization.where(carrier_profile: {"$ne" => nil}).each do |org|
  # carrier_profile = org.carrier_profile

  org_params = {
    hbx_id: org.hbx_id,
    home_page: org.home_page,
    legal_name: org.legal_name,
    dba: org.dba,
    entity_kind: :c_corporation
  }

  organization = BenefitSponsors::Organizations::Organization.new(org_params)
  profile = BenefitSponsors::Organizations::IssuerProfile.new({is_benefit_sponsorship_eligible: false})
  profile.office_locations.build(org.office_locations.first.attributes)
  organization.profiles << profile
  organization.site = site
  organization.save
end

puts "Creating Rating Area and Service Area.."
county_zip = ::BenefitMarkets::Locations::CountyZip.new(county_name: "Hampden", zip: "01001", state: "#{Settings.aca.state_abbreviation}")
county_zip.save
rating_area = BenefitMarkets::Locations::RatingArea.new(covered_states: ["#{Settings.aca.state_abbreviation}"], county_zip_ids: [county_zip.id], exchange_provided_code: "#{Settings.aca.state_abbreviation}", active_year: 2018)
rating_area.save

issuer_id = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").first.id

service_area = BenefitMarkets::Locations::ServiceArea.new(covered_states: ["#{Settings.aca.state_abbreviation}"], issuer_id: issuer_id,county_zip_ids: [county_zip.id], issuer_provided_code: "#{Settings.aca.state_abbreviation}", active_year: 2018)
service_area.save

puts "Loading Products..."
Plan.where(:market => 'shop', :coverage_kind => 'health', :active_year => 2018).each do |plan|

  carrier         = plan.carrier_profile
  issuer_profile  = BenefitSponsors::Organizations::IssuerProfile.find_by_issuer_name(carrier.legal_name)

  attribute_map = {

    :hbx_id                     => :hbx_id,
    :name                       => :title,
    :market                     => :benefit_market_kind,

    :hios_id                    => :hios_id,
    :hios_base_id               => :hios_base_id,
    :csr_variant_id             => :csr_variant_id,

    :plan_type                  => :health_plan_kind,
    :metal_level                => :metal_level_kind,

    :ehb                        => :ehb,
    :is_standard_plan           => :is_standard_plan,

    :provider_directory_url     => :provider_directory_url,
    :rx_formulary_url           => :rx_formulary_url,

    # "minimum_age"=>14,
    # "maximum_age"=>64,

    # "is_active"=>true,

    # "deductible"=>"$5,000",
    # "family_deductible"=>"$5000 per person | $10000 per group",

    # "nationwide"=>false,
    # "dc_in_network"=>true,
  }


  product = BenefitMarkets::Products::HealthProducts::HealthProduct.new
  attribute_map.each_pair { |old_attr, new_attr| product.write_attribute(new_attr, plan.send(old_attr))}

  product.benefit_market_kind = :aca_shop
  product.application_period = Date.new(plan.active_year,1,1)..Date.new(plan.active_year,12,31)
  product.product_package_kinds = [:single_issuer, :metal_level, :single_product]


  premium_tables = plan.premium_tables.inject({}) do |premium_tables, premium_row|
    effective_period = premium_row.start_on..premium_row.end_on
    premium_tables[effective_period] ||= []
    # premium_tables[effective_period] << BenefitMarkets::Products::PremiumTuple.new(age: premium_row.age, cost: premium_row.cost)
    premium_tables
  end

  premium_tables.each do |effective_period, premium_tuples|
    # product.premium_tables << BenefitMarkets::Products::PremiumTable.new(effective_period: effective_period, premium_tuples: premium_tuples, rating_area: BenefitMarkets::Locations::RatingArea.first)
    product.premium_tables << BenefitMarkets::Products::PremiumTable.new(effective_period: effective_period, rating_area: BenefitMarkets::Locations::RatingArea.first)
  end

  product.is_reference_plan_eligible = true
  product.service_area = BenefitMarkets::Locations::ServiceArea.first

  product.issuer_profile_id = issuer_profile.id
  product.sbc_document = plan.sbc_document
  product.save!
end

puts "Creating Benefit Market..."
benefit_market = ::BenefitMarkets::BenefitMarket.create!({
  kind: :aca_shop,
  title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Market",
  site_urn: "#{Settings.aca.state_abbreviation}",
  description: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} Shop Market",
  configuration: BenefitMarkets::Configurations::Configuration.new
})

puts "Creating Benefit Market Catalog..."
benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
  title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Benefit Catalog",
  application_interval_kind: :monthly,
  application_period: Date.new(2018,1,1)..Date.new(2018,12,31),
  probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
})

puts "Creating Product Packages..."
benefit_market_catalog.product_packages.create!({product_kind: :health, title: 'Single Issuer', kind: :single_issuer, application_period: benefit_market_catalog.application_period})
benefit_market_catalog.product_packages.create!({product_kind: :health, title: 'Metal Level', kind: :metal_level, application_period: benefit_market_catalog.application_period})
benefit_market_catalog.product_packages.create!({product_kind: :health, title: 'Single Product', kind: :single_product, application_period: benefit_market_catalog.application_period})

dc_contribution_model = ::BenefitMarkets::ContributionModels::ContributionModel.where(title: "#{Settings.aca.state_abbreviation} Shop Contribution Model").first
dc_pricing_model = ::BenefitMarkets::PricingModels::PricingModel.where(name: "#{Settings.aca.state_abbreviation} Shop Pricing Model").first

benefit_market_catalog.product_packages.each do |product_package|
  product_package.contribution_model = dc_contribution_model
  product_package.pricing_model = dc_pricing_model
  product_package.save!
end

puts "Associating Products with Product Packages..."
%w(single_product metal_level single_issuer).each do |kind|
  if product_package = benefit_market_catalog.product_packages.detect{|package| package.kind == kind.to_sym}
    product_package.products = BenefitMarkets::Products::HealthProducts::HealthProduct.where(:product_package_kinds => /#{kind}/).to_a
    product_package.save
  end
end