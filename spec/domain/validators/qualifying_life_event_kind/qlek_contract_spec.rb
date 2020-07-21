# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::QualifyingLifeEventKind::QlekContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:contract_params) do
    { start_on: "#{TimeKeeper.date_of_record.year}-07-01",
      end_on: "#{TimeKeeper.date_of_record.year}-08-01",
      title: 'Test Title',
      tool_tip: 'jhsdjhs',
      pre_event_sep_in_days: '10',
      is_self_attested: true,
      reason: 'Lost Access To Mec',
      post_event_sep_in_days: '88',
      market_kind: 'individual',
      effective_on_kinds: ['date_of_event']}
  end

  context 'success case' do
    before  do
      @result = subject.call(contract_params)
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end

    it 'should not have any errors' do
      expect(@result.errors.empty?).to be_truthy
    end

    it 'should set dehumanized form for title' do
      expect(@result.to_h[:reason]).to eq('lost_access_to_mec')
    end

    context 'for end_on being optional' do
      before do
        contract_params.merge!({end_on: nil})
        @result = subject.call(contract_params)
      end

      it 'should return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should not have any errors' do
        expect(@result.errors.empty?).to be_truthy
      end
    end
  end

  context 'failure case' do
    context 'end on date is less than start on date' do
      before  do
        contract_params.merge!({start_on: "#{TimeKeeper.date_of_record.year}-08-19"})
        @result = subject.call(contract_params)
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should have any errors' do
        expect(@result.errors.empty?).to be_falsy
      end

      it 'should return error message as start date is after end date' do
        expect(@result.errors.messages.first.text).to eq('End on must be after start on date')
      end
    end

    context 'one of the effective_on_kinds is not valid for given market kind' do
      before  do
        contract_params.merge!({effective_on_kinds: ['first_of_this_month']})
        @result = subject.call(contract_params)
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should have any errors' do
        expect(@result.errors.empty?).to be_falsy
      end

      it 'should return error message as start date is after end date' do
        expect(@result.errors.messages.first.text).to eq('one of the selected values is invalid')
      end
    end

    context 'duplicate reason' do
      let!(:qlek) do
        FactoryBot.create(:qualifying_life_event_kind, reason: 'lost_access_to_mec', market_kind: 'individual')
      end

      before  do
        @result = subject.call(contract_params)
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should have any errors' do
        expect(@result.errors.empty?).to be_falsy
      end

      it 'should return error message as start date is after end date' do
        expect(@result.errors.messages.first.text).to eq('sep type object exists with same reason')
      end
    end

    context 'invalid end_on value' do
      before do
        contract_params.merge!({end_on: 'test'})
        @result = subject.call(contract_params)
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should return error message as end_on is not a date' do
        expect(@result.errors.messages.first.text).to eq('must be a date')
      end
    end
  end
end
