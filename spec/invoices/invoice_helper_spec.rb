require "rails_helper"

RSpec.describe InvoiceHelper, :type => :helper do
  let(:organization) { instance_double("Organization") }

  let(:address_1) { double("Address1") }
  let(:address_2) { double("Address2") }

  let(:office_location_1) { double("OfficeLocation1",address: address_1) }
  let(:office_location_2) { double("OfficeLocation2",address: address_2) }


  context "#mailing_or_primary_address" do

    it "returns mailing address if only mailing address is present" do
      allow(address_1).to receive(:mailing?).and_return(true)
      allow(organization).to receive(:office_locations).and_return([office_location_1])
      expect(helper.mailing_or_primary_address(organization)).to eq address_1
    end

    it "returns mailing address if both mailing and primary addresses are present" do
      allow(address_1).to receive(:mailing?).and_return(true)
      allow(address_2).to receive(:mailing?).and_return(false)
      allow(organization).to receive(:office_locations).and_return([office_location_1, office_location_2])
      expect(helper.mailing_or_primary_address(organization)).to eq address_1
    end

    it "returns primary address if mailing address is not present" do
      allow(address_2).to receive(:mailing?).and_return(false)
      allow(organization).to receive(:office_locations).and_return([office_location_2])
      expect(helper.mailing_or_primary_address(organization)).to eq address_2
    end

  end

end