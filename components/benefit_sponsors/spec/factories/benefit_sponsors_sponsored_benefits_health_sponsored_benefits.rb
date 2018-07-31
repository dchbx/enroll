FactoryGirl.define do
  factory :benefit_sponsors_sponsored_benefits_health_sponsored_benefit, class: 'BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit', parent: :benefit_sponsors_sponsored_benefits_sponsored_benefit do
    
    sponsor_contribution { build(:benefit_sponsors_sponsored_benefits_sponsor_contribution) }

    transient do
      product_package nil
    end

    after(:build) do |sponsored_benefit, evaluator|
      if evaluator.product_package
        sponsored_benefit.product_package_kind = evaluator.product_package.package_kind
        sponsored_benefit.reference_product_id = evaluator.product_package.products[0].id
        build(:benefit_sponsors_sponsored_benefits_sponsor_contribution, sponsored_benefit: sponsored_benefit, product_package: evaluator.product_package)
      end
    end
  end
end
