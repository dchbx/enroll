# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationForms::OrganizationFormContract do

  let(:phone) do
    {
      kind: "work", area_code: "483", number: "7897489", extension: nil
    }
  end

  let(:address) do
    {
      kind: 'home', address_1: 'test', address_2: nil, city: 'test', state: 'DC', zip: '22031', county: nil
    }
  end

  let(:office_location) do
     {
       is_primary: true, address: address, phone: phone
     }
  end

  let(:profile) do
    {
      profile_type: 'broker_agency',
      office_locations_attributes: {"0" => office_location}
    }
  end

  let(:params) do
    {
      profile_type: 'broker_agency',
      dba: nil, profile: profile, fein: nil
    }
  end

  let(:error_message)    { {:legal_name => ["is missing"], :entity_kind => ['is missing']} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge({legal_name: 'test', entity_kind: :s_corporation})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
