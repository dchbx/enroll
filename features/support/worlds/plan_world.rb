module PlanWorld
  def plan(*traits)
    attributes = traits.extract_options!
    @plan ||= FactoryBot.create :plan, *traits, attributes
  end

  def create_cat_product
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile, metal_level_kind: :catastrophic)
  end
end

World(PlanWorld)

Given /a plan year(?:, )?(.*)(?:,) exists/ do |traits|
  plan *traits.sub(/, (and )?/, ',').gsub(' ', '_').split(',').map(&:to_sym), market: 'shop', coverage_kind: 'health', deductible: 4000
end
