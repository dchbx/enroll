require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_broker_agency_accounts")

describe RemoveDuplicateBrokerAgencyAccounts do
  let(:given_task_name) { "remove_duplicate_broker_agency_accounts" }
  # broker_agency_account moved to engine
  let!(:broker_agency_profile) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_broker_agency_profile).broker_agency_profile}
  let(:broker_agency_account) {BenefitSponsors::Accounts::BrokerAgencyAccount.new(start_on:Date.today,benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,is_active: true)}
  let(:broker_agency_account2) {BenefitSponsors::Accounts::BrokerAgencyAccount.new(start_on:Date.today,benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,is_active: true)}

  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, broker_agency_accounts:[broker_agency_account, broker_agency_account2])}

  subject { RemoveDuplicateBrokerAgencyAccounts.new(given_task_name, double(:current_scope => nil)) }
  
  it "should get remove duplicate broker agency accounts from families" do
    expect(family.broker_agency_accounts.size).to eq 2
    subject.migrate
    family.reload
    expect(family.broker_agency_accounts.size).to eq 1
  end
    
end