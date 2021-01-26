# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationForms::RegistrationFormContract do

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

  let(:organization_params) do
    {
      profile_type: 'broker_agency',
      dba: nil, profile: profile, fein: '123456789',
      legal_name: 'test', entity_kind: :s_corporation
    }
  end

  let(:staff_role_params) do
    {
      first_name: 'test', last_name: 'test',
      dob: "01/01/1988", profile_type: 'benefit_sponsor', email: 'test@test.com'
    }
  end

  let(:params) do
    {
      profile_type: 'benefit_sponsor'
    }
  end

  let(:error_message)    { {:staff_roles_attributes => ["is missing"], :organization => ['is missing']} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge({staff_roles_attributes: {"0" => staff_role_params}, organization: organization_params})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params.merge(staff_roles_attributes: [staff_role_params])
      end
    end
  end
end
