# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_sponsored_benefits_sponsored_benefit, class: 'BenefitSponsors::SponsoredBenefits::SponsoredBenefit' do

    benefit_package { create(:benefit_sponsors_benefit_packages_benefit_package) }
    product_package_kind  { :single_issuer }
    reference_product { FactoryBot.build(:benefit_markets_products_health_products_health_product) }
  end
end
