# frozen_string_literal: true

require "rails_helper"

RSpec.describe Entities::SecureMessages::Message do

  context "Given valid required parameters" do

    let(:contract)      { Validators::SecureMessages::MessageContract.new }
    let(:required_params) do
      {
        subject: 'test',
        body: 'test',
        from: "test"
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new Organization instance" do
        expect(described_class.new(required_params)).to be_a Entities::SecureMessages::Message
      end
    end
  end
end