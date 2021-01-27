# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationForms::ProfileFormContract do

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
      address: address, phone: phone
    }
  end

  let(:params) do
    {
      office_locations_attributes: {"0" => office_location}
    }
  end


  let(:error_message)    { {:market_kind => ["Please enter market kind"], :profile_type => ["is missing"]} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end

    context 'sending missing parameters if profile is broker agency or general agency' do
      it 'should throw an error if broker agency' do
        missing_params = {:profile_type => 'broker_agency', office_locations_attributes: {"0" => office_location}}
        expect(subject.call(missing_params).failure?).to be_truthy
        expect(subject.call(missing_params).errors.to_h).to eq({:market_kind => ["Please enter market kind"]})
      end

      it 'should throw an error if general agency' do
        missing_params = {:profile_type => 'general_agency', office_locations_attributes: {"0" => office_location}}
        expect(subject.call(missing_params).failure?).to be_truthy
        expect(subject.call(missing_params).errors.to_h).to eq({:market_kind => ["Please enter market kind"]})
      end
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge!({profile_type: 'benefit_sponsor'})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params.merge(office_locations_attributes: [office_location])
      end
    end
  end
end
