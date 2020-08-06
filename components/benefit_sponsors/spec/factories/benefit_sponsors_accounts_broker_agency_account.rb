# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_accounts_broker_agency_account, class: 'BenefitSponsors::Accounts::BrokerAgencyAccount' do

    transient do
      broker_agency_profile { nil }
      benefit_sponsorship { nil }
    end

    start_on                { TimeKeeper.date_of_record }
    writing_agent           { FactoryBot.create(:broker_role)}

    after(:build) do |broker_agency_account, evaluator|
      broker_agency_account.broker_agency_profile = (evaluator.broker_agency_profile || FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile))
    end

    after(:build) do |broker_agency_account, evaluator|
      broker_agency_account.benefit_sponsorship = (evaluator.benefit_sponsorship || FactoryBot.build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile, site: BenefitSponsors::Site.by_site_key(:cca).first))
    end
  end
end
