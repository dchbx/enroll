# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::OfficeLocations::OfficeLocationContract do

  let(:missing_params)   { {} }
  let(:error_message)    { {:address => ['is missing'], :phone => ['is missing']} }

  let(:address) {{kind: 'primary', address_1: 'test', city: 'fair', state: 'DC', zip: '22001'}}
  let(:phone) {{kind: 'home', area_code: '123', number: '1234567'}}


  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({address: address, phone: phone})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
