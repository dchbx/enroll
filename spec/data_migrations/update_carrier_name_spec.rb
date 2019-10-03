require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carrier_name")

describe UpdateCarrierName, dbclean: :after_each do

  let(:given_task_name) { "update_carrier_name" }
  subject { UpdateCarrierName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update carrier legal name" do
    let(:carrier_profile)  { FactoryBot.create(:carrier_profile, abbrev: "abcxyz")}
    let(:new_legal_name) { "New Legal Name" }

    it "should update carrier name in old model" do
      organization = carrier_profile.organization
      ClimateControl.modify abbrev: carrier_profile.abbrev.to_s, name: new_legal_name do
        subject.migrate
      end
      organization.reload
      expect(organization.legal_name).to match(new_legal_name)
    end
  end

  describe "update carrier legal name in exempt_organization" do
    let(:site) { build(:benefit_sponsors_site, :with_owner_exempt_organization, Settings.site.key) }
    let(:issuer_profile) { create(:benefit_sponsors_organizations_issuer_profile, organization: site.owner_organization, abbrev: "abcxyz") }

    let(:new_legal_name) { "New Legal Name" }

    it "should update carrier name in old model" do
      ClimateControl.modify abbrev: issuer_profile.abbrev, name: new_legal_name do
        subject.migrate
      end
      issuer_profile.organization.reload
      expect(issuer_profile.organization.legal_name).to match(new_legal_name)
    end
  end
end
