require 'rails_helper'

module TransportGateway
  RSpec.describe Message, type: :model do

    context ".new" do
      let(:source_host) { "www.example.com" }
      let(:source_path) { "/path/to/source/folder" }
      let(:target_host) { "www.example.com" }
      let(:target_path) { "path/to/target/folder" }
      let(:from)        { source_host + source_path }
      let(:to)          { target_host + target_path }
      let(:to_uri)      { URI.parse(to) }
      let(:body)        { "madam in eden i'm adam" }

      let(:valid_params) do
        {
          from: from,
          to: to,
          body: body
        }
      end

      context "with no arguments" do
        let(:params)  {{}}

        it "should instantiate a Message instance" do
          expect(Message.new(**params)).to be_an_instance_of(Message)
        end
      end

      context "with no 'from' argument" do
        let(:params)  { valid_params.except(:from) }

        it "should not raise an error" do
          expect{ Message.new(**params) }.not_to raise_error 
        end
      end

      context "with no 'to' argument" do
        let(:params)  { valid_params.except(:to) }

        it "should not raise an error" do
          expect{ Message.new(**params) }.not_to raise_error 
        end
      end

      context "with no 'body' argument" do
        let(:params)  { valid_params.except(:body) }

        it "should not raise an error" do
          expect{ Message.new(**params) }.not_to raise_error 
        end
      end

      context "with a unparseable URI in 'to' argument" do
        let(:invalid_uri)  { "@7463$%^&*" }

        it "should raise Invalid URI error" do
          expect{ Message.new(from: from, to: invalid_uri, body: body) }.to raise_error(URI::InvalidURIError) 
        end
      end      

      context "with valid arguments" do
        let(:params)  { valid_params }

        it "should not raise an error" do
          expect{Message.new(**params)}.not_to raise_error 
        end

        it "should set the instance vars" do
          expect(Message.new(**params).from).to eq from
          expect(Message.new(**params).body).to eq body
        end

        it "should cast the 'to' argument as a URI" do
          expect(Message.new(**params).to).to eq to_uri
        end
      end

    end
  end
end
