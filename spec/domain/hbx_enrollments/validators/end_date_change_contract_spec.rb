# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollments::Validators::EndDateChangeContract, dbclean: :after_each do
  let(:params) do
    {enrollment_id: BSON::ObjectId.new.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true}
  end

  context 'for success case' do
    before do
      @result = subject.call(params)
    end

    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
    end

    it 'should return Dry::Validation::Result object' do
      expect(@result).to be_a ::Dry::Validation::Result
    end

    it 'should not return any errors' do
      expect(@result.errors.to_h).to be_empty
    end
  end

  context 'for failure case' do
    before do
      @result = subject.call({enrollment_id: BSON::ObjectId.new.to_s, new_term_date: TimeKeeper.date_of_record})
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).not_to be_empty
    end

    it 'should return any errors' do
      expect(@result.errors.to_h).to eq({:edi_required => ["is missing"]})
    end


  end
end