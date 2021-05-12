require "rails_helper"
require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "update_office_location")

describe UpdateOfficeLocation do

  let(:given_task_name) { "update_office_location" }
  subject { UpdateOfficeLocation.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing an existing office location" do
    let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }

    around do |example|
      ClimateControl.modify org_hbx_id: broker_agency_profile.organization.hbx_id,
                            address_kind: 'primary',
                            address_1: "123 Main Street NE",
                            city: "Gotham",
                            state_code: 'DC',
                            zip: "30495" do
        example.run
      end
    end

    it "should updating the existing primary address" do
      expect(broker_agency_profile.office_locations.present?).to eq(true)

      subject.migrate
      broker_agency_profile.office_locations.first.reload

      office_address = broker_agency_profile.office_locations.first.address.address_1
      expect(office_address).to eq('123 Main Street NE')
    end

    it "should not create a new address if a match does not exist" do
      broker_agency_profile.office_locations.destroy_all
      expect(broker_agency_profile.office_locations.count).to eq 0

      subject.migrate
      broker_agency_profile.reload

      expect(broker_agency_profile.office_locations.count).to eq 0
    end

  end
end
