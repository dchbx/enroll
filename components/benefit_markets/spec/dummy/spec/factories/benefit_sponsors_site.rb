FactoryBot.define do
  factory :benefit_sponsors_site, class: 'BenefitSponsors::Site' do
    site_key    { :acme }
    byline      { "ACME Healthcare" }
    long_name   { "ACME Widget's Benefit Website" }
    short_name  { "Benefit Website" }
    domain_name { "hbxshop.org" }

    transient do
      kind { :aca_shop }
    end

    trait :with_owner_exempt_organization do
      after :build do |site, evaluator|
       site.owner_organization = build(:benefit_sponsors_organizations_exempt_organization, :with_hbx_profile, site: site)
      end
    end

    trait :with_benefit_market do
      after :build do |site, evaluator|
        site.benefit_markets << create(:benefit_markets_benefit_market, kind: evaluator.kind, site: site)
      end
    end

    trait :as_hbx_profile do
      after :build do |site, evaluator|
        site.owner_organization = build(:benefit_sponsors_organizations_exempt_organization, :with_hbx_profile, site: site)
      end
    end

    trait :with_benefit_market_catalog_and_product_packages do
      after :create do |site, evaluator|
        create(:benefit_markets_benefit_market_catalog, :with_product_packages, benefit_market: site.benefit_markets[0], issuer_profile: BenefitSponsors::Organizations::IssuerProfile.new)
      end
    end

    trait :cca do
      site_key { :cca }
    end

    trait :dc do
      site_key { :dc }
    end
  end
end
