require 'rails_helper'

describe CuramApplicationLookup do
  let(:person_demographics) { { :first_name => "John", :last_name => "Doe", :ssn => "345678900", :dob => "19900120" } }

  describe "with a slugged configuration" do
    it "returns no data found" do
      expect(CuramApplicationLookup.instance.search_curam_financial_app(person_demographics)).to eq 302
    end
  end

  describe "with an AMQP source" do
    let(:generator) { CuramApplicationLookup::AmqpSource }
    let(:valid_response_code) { 404 }
    let(:amqp_response) { {:return_status => valid_response_code} }

    it "returns a valid response code" do
      allow(Acapi::Requestor).to receive(:request).with("account_management.check_existing_account", person_demographics, 2).and_return(amqp_response)
      expect(generator.search_curam_financial_app(person_demographics)).to eq valid_response_code
    end
  end
end
