require 'rails_helper'

RSpec.describe 'ConditionalFieldsLookupService' do
  include_examples 'submitted application with two active members and one applicant'

  subject do
    FinancialAssistance::Services::ConditionalFieldsLookupService.new
  end

  describe 'constants' do
    it 'should return true as the data matches' do
      expect(::FinancialAssistance::Services::ConditionalFieldsLookupService::APPLICANT_DRIVER_QUES).to eq [:is_required_to_file_taxes, :is_claimed_as_tax_dependent]
    end
  end

  describe 'displayable_field?' do
    context 'with invalid arguments' do
      it 'should return false as the class name is not valid' do
        expect(subject.displayable_field?("", "bson_id", :attribute)).to eq false
      end
    end

    context 'with valid arguments' do
      it 'should return true as the attribute is a driver question' do
        expect(subject.displayable_field?("applicant", "bson_id", :is_claimed_as_tax_dependent)).to eq true
      end
    end
  end
end
