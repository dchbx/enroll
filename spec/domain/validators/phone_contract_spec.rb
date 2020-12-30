# frozen_string_literal: true

require 'rails_helper'

module Validators
  RSpec.describe PhoneContract,  dbclean: :after_each do

    subject do
      described_class.new.call(params)
    end

    describe 'missing kind and full_phone_number field' do

      let(:params) do
        { }
      end
      let(:error_message) {{:kind => ['is missing'], :full_phone_number => ['is missing']}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end


    describe 'empty kind and full_phone_number fields' do

      let(:params) do
        {kind: '', full_phone_number: ''}
      end


      it 'success' do
        expect(subject).to be_success
      end
    end

    describe 'passing valid kind and full_phone_number fields' do

      let(:params) do
        {kind: 'test', full_phone_number: '9898989898'}
      end

      it 'passes' do
        expect(subject).to be_success
      end
    end
  end
end
