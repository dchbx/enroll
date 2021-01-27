# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationContract do

  let(:missing_params)   { {legal_name: 'abc_organization', entity_kind: :limited_liability_corporation} }
  let(:error_message)    { {:site_id => ["is missing"], :profiles => ["is missing"]} }

  let(:phone) do
    {
      kind: "work", area_code: "483", number: "7897489", full_phone_number: "4837897489"
    }
  end

  let(:address) do
    {
      kind: 'primary', address_1: "dc", address_2: "dc", city: "dc", state: "DC", zip: "12345"
    }
  end

  let(:office_location) do
    {
      is_primary: true, address: address, phone: phone
    }
  end

  let(:profile) do
    {
      is_benefit_sponsorship_eligible: false, contact_method: :test, corporate_npn: "1234567",
      office_locations: [office_location]
    }
  end

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({site_id: BSON::ObjectId.new, profiles: [profile] })}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end

    context "with valid all params" do
      let(:all_params) do
        valid_params.merge({home_page: nil, dba: nil})
      end 

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end