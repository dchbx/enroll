# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_sponsored_benefits_dental_sponsored_benefit, class: 'BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit', parent: :benefit_sponsors_sponsored_benefits_sponsored_benefit do
    sponsor_contribution { build(:benefit_sponsors_sponsored_benefits_sponsor_contribution) }

    transient do
      product_package { nil }
    end

    after(:build) do |sponsored_benefit, evaluator|
      product_package = evaluator.product_package

      if product_package
        sponsored_benefit.product_package_kind = product_package.package_kind
        sponsored_benefit.reference_product_id = product_package.products[0].id

        if product_package.package_kind == :multi_product
          sponsored_benefit.elected_product_choices = product_package.products.pluck(:id)[0..1]
        else
          sponsored_benefit.product_option_choice = evaluator.product_package.products[0].issuer_profile_id
        end

        sponsored_benefit.sponsor_contribution = build(:benefit_sponsors_sponsored_benefits_sponsor_contribution, sponsored_benefit: sponsored_benefit, product_package: evaluator.product_package)
      end
    end
  end
end
