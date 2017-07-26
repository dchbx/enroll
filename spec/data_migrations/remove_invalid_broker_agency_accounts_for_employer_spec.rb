require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_broker_agency_accounts_for_employer")

describe RemoveInvalidBrokerAgencyAccountsForEmployer, dbclean: :after_each do
  let(:given_task_name) { "remove_invalid_broker_agency_accounts_for_employer" }
  subject { RemoveInvalidBrokerAgencyAccountsForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer profile with broker agency accounts", dbclean: :after_each do

    let(:organization) {FactoryGirl.create(:organization)}
    let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:invalid_broker_agency_account) {FactoryGirl.create(:broker_agency_account)}
    let(:valid_broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile)}
    let(:employer_profile){ FactoryGirl.build(:employer_profile,broker_agency_accounts:[invalid_broker_agency_account,valid_broker_agency_account]) }
    let(:organization1) {FactoryGirl.create(:organization,employer_profile:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization1.fein)
    end

    context "employer profile with invalid broker agency account" do

      it "should delete broker agency accounts with no writing agent" do
        invalid_broker_agency_account.update_attribute(:writing_agent_id,nil)
        employer_profile.reload
        invalid_agency_account = employer_profile.broker_agency_accounts.where(id:invalid_broker_agency_account.id).first
        expect(employer_profile.broker_agency_accounts.unscoped.count).to eq 2
        expect(invalid_agency_account.writing_agent.present?).to eq false

        subject.migrate
        employer_profile.reload
        expect(employer_profile.broker_agency_accounts.unscoped.count).to eq 1
        expect(employer_profile.broker_agency_accounts.first).to eq valid_broker_agency_account
      end
    end

    context "employer profile with valid broker agency account" do

      it "should not delete valid broker agency accounts" do
        expect(employer_profile.broker_agency_accounts.unscoped.count).to eq 2

        subject.migrate
        expect(employer_profile.broker_agency_accounts.unscoped.count).to eq 2
      end

    end

  end
end
