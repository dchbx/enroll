require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_broker_agency_account_for_employer")

describe CreateBrokerAgencyAccountForEmployer, dbclean: :after_each do
  let(:given_task_name) { "create_broker_agency_account_for_employer" }
  subject { CreateBrokerAgencyAccountForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should create broker_agency_accounts for employer" do

    let!(:employer_profile) { FactoryGirl.build(:employer_profile)}
    let!(:organization) { FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let!(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile)}
    let!(:br_agency_organization) { FactoryGirl.create(:organization,broker_agency_profile:broker_agency_profile)}
    let!(:broker_role) { FactoryGirl.create(:broker_role,languages_spoken: ["rrrrr"],broker_agency_profile_id:broker_agency_profile.id, aasm_state:'active')}

    before(:each) do
      allow(br_agency_organization.broker_agency_profile).to receive(:active_broker_roles).and_return([broker_role])
      allow(ENV).to receive(:[]).with("emp_hbx_id").and_return(organization.hbx_id)
      allow(ENV).to receive(:[]).with("br_agency_hbx_id").and_return(br_agency_organization.hbx_id)
      allow(ENV).to receive(:[]).with("br_npn").and_return(broker_role.npn)
      allow(ENV).to receive(:[]).with("br_start_on").and_return(TimeKeeper.date_of_record.to_s)
    end

    it "should have broker_agency_account for employer" do
      expect(employer_profile.broker_agency_accounts.size).to eq 0 # before migration
      subject.migrate
      employer_profile.reload
      expect(employer_profile.broker_agency_accounts.size).to eq 1 # after migration
    end
  end
end
