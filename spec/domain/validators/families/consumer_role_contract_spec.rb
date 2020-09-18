# frozen_string_literal: true

require 'rails_helper'

module Validators
  RSpec.describe Families::ConsumerRoleContract,  dbclean: :after_each do

    subject do
      described_class.new.call(params)
    end

    describe 'missing all fields' do

      let(:params) do
        { }
      end

      it "passes" do
        expect(subject).to be_success
      end
    end

    describe 'optional fields with empty values' do

      let(:params) do
        {is_applying_coverage: nil, is_active: nil, is_applicant: nil }
      end
      let(:error_message) {{:is_applying_coverage => ['must be filled'], :is_applicant => ['must be filled']}}

      it 'fails' do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe 'passing optional fileds with values' do

      let(:params) do
        {is_applying_coverage: true, is_active: true, is_applicant: true }
      end

      it 'passes' do
        expect(subject).to be_success
      end
    end
  end
end
