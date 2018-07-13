FactoryGirl.define do
  factory :benefit_sponsors_accounts_broker_agency_account, class: 'BenefitSponsors::Accounts::BrokerAgencyAccount' do

    transient do
      broker_agency_profile nil
      benefit_sponsorship nil
    end

    start_on                TimeKeeper.date_of_record
    writing_agent           { FactoryGirl.create(:broker_role)}

    after(:build) do |broker_agency_account, evaluator|
      if evaluator.broker_agency_profile
        broker_agency_account.broker_agency_profile = evaluator.broker_agency_profile
      else
        broker_agency_account.broker_agency_profile = FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile)
      end
    end

    after(:build) do |broker_agency_account, evaluator|
      if evaluator.benefit_sponsorship
        broker_agency_account.benefit_sponsorship = evaluator.benefit_sponsorship
      else
        broker_agency_account.benefit_sponsorship = FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile)
      end
    end
  end
end
