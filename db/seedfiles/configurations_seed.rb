Dir.glob('db/seedfiles/configurations/*').each do |file|
  require_relative 'configurations/' + File.basename(file,File.extname(file))
end

puts "*"*80 unless Rails.env.test?
puts "::: Generating Configurations :::"

# MAIN_TRANSLATIONS = {
#   "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal",
#   "en.shared.my_portal_links.my_broker_agency_portal" => "My Broker Agency Portal",
#   "en.shared.my_portal_links.my_employer_portal" => "My Employer Portal"
# }

configurations = [
  SHOP_CONFIGURATIONS,
  # IVL_CONFIGURATIONS
].reduce({}, :merge)

unless Rails.env.test?
  p configurations
end

benefit_market = BenefitMarkets::BenefitMarket.by_kind(:aca_shop)

configurations.keys.each do |key|
  benefit_market[key.to_s] = configurations[key]
  # BenefitMarkets::Configurations::Configuration[benefit_market, key.to_s] = configurations[key]
end

puts "::: Configurations Complete :::"
puts "*"*80 unless Rails.env.test?