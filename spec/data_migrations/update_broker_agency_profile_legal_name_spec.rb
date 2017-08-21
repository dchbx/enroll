require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_profile_legal_name")

describe UpdateBrokerAgencyProfileLegalName, dbclean: :after_each do

  let(:given_task_name) { "update_broker_agency_profile_legal_name" }
  subject { UpdateBrokerAgencyProfileLegalName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update the legal name of the broker agency profile" do


    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
    let(:organization) { broker_agency_profile.organization }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return organization.fein
      allow(ENV).to receive(:[]).with("new_legal_name").and_return "agency2"
    end

    context "change the legal name of broker agency profile", dbclean: :after_each do
      it "should update the broker agency profile legal name" do
        expect(broker_agency_profile.legal_name).to eq(organization.legal_name)
        subject.migrate
        organization.reload
        expect(organization.broker_agency_profile.legal_name).to eq("agency2")
      end
    end
  end
end
