require 'rails_helper'

module TransportGateway
  RSpec.shared_examples "a transport gateway adapter, sending a message" do
    describe "given:
    - no destination
    " do
      let(:message) { TransportGateway::Message.new(to: nil, from: "something", body: "somebody") }

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /destination not provided/) 
      end
    end
  end
end
