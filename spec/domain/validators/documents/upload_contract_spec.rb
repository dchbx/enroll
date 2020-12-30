# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Documents::UploadContract,  dbclean: :after_each do

  describe 'message contract' do

    context 'sending with missing values should return errors' do
      let(:invalid_params) { {subjects: [], id: "", document_type: "", source: "" } }
      let(:error_message) do
        {:subjects => ['Missing attributes for subjects'], :id => ['Doc storage Identifier is blank'],
         :document_type => ['Document type is missing'], :source => ['Invalid source']}
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(subject.call(invalid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context "sending with missing keys should return errors" do

      let(:invalid_params) { {} }
      let(:error_message) do
        {:subjects => ['is missing'], :id => ['is missing'],
         :document_type => ['is missing'], :source => ['is missing']}
      end

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context 'sending with all keys and values should not errors' do

      let(:valid_params) do
        {subjects: [id: BSON::ObjectId.new.to_s, type: 'notice'],
         id: BSON::ObjectId.new.to_s, document_type: 'test', source: 'enroll_system'}
      end


      it 'should return Dry::Validation::Result object' do
        expect(subject.call(valid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(subject.call(valid_params).errors.to_h).to be_empty
      end
    end
  end
end
