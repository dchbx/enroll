FactoryGirl.define do
  factory :benefit_sponsors_site, class: 'BenefitSponsors::Site' do
    site_key    :acme
    byline      "ACME Healthcare"
    long_name   "ACME Widget's Benefit Website"
    short_name  "Benefit Website"
    domain_name "hbxshop.org"

    transient do
      kind :aca_shop
    end

    trait :with_owner_general_organization do
      after :build do |site, evaluator|
        site.owner_organization = build(:benefit_sponsors_organizations_general_organization, :with_hbx_profile, site: site)
      end
    end

    trait :with_owner_exempt_organization do
      after :build do |site, evaluator|
        site.owner_organization = build(:benefit_sponsors_organizations_exempt_organization, :with_hbx_profile, site: site)
      end
    end

    trait :with_benefit_market do
      after :build do |site, evaluator|
        site.benefit_markets << build(:benefit_markets_benefit_market, kind: evaluator.kind)
      end
    end

    trait :with_benefit_market_catalog do
      after :create do |site, evaluator|
        create(:benefit_markets_benefit_market_catalog, benefit_market: site.benefit_markets[0])
      end
    end

    trait :dc do
      site_key :dc
    end

    trait :cca do
      site_key :cca
    end
  end
end
