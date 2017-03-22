require 'rails_helper'

describe Api::V1::EsiController do
  let(:request_xml) { File.read(Rails.root.join("spec", "test_data", "esi_payloads", "request.xml")) }
  let(:response_xml) { File.read(Rails.root.join("spec", "test_data", "esi_payloads", "response.xml")) }
  let(:person) { FactoryGirl.create(:person) }

  context "valid request" do
    it 'returns https status 200' do
      allow(HappyMapper).to receive(:parse).with(anything).and_return(HappyMapper.parse(request_xml))
      allow_any_instance_of(ActionController::Rendering).to receive(:render).and_return(response_xml)
      allow(Person).to receive(:matchable).and_return([person])

      post :roster, {:format => "xml"}
      expect(response.status).to eq(200)
    end
  end

  context "invalid request" do
    it 'returns https status 422' do
      allow(HappyMapper).to receive(:parse).with(anything).and_raise(Exception.new)

      post :roster, {:format => "xml"}
      expect(response.status).to eq(422)
    end
  end
end
