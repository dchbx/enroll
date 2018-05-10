FactoryGirl.define do
  factory :plan_design_benefit_sponsorship, class: 'SponsoredBenefits::BenefitSponsorships::BenefitSponsorship' do
    benefit_market 'aca_shop_cca'
  end
end
