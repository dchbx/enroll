# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::OfficeLocations::AddressContract do

  let(:params)   { {address_1: 'test', city: 'fair',  zip: '22001'} }
  let(:error_message)    { {:kind => ['is missing'], :state => ['is missing']} }

  let(:address) {{kind: 'primary', address_1: 'test', city: 'fair', state: 'DC', zip: '22001'}}



  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end

    context "sending parameters with invalid data should fail validation with errors" do
      let(:invalid_params) { params.merge({kind: 'primary', state: '123'})}

      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq({:state => ["Invalid state"]}) }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge({kind: 'primary', state: 'DC'})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
