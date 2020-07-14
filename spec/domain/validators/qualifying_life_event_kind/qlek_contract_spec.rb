# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::QualifyingLifeEventKind::QlekContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'success case' do
    let(:contract_params) do
      { start_on: "#{TimeKeeper.date_of_record.year}-07-01",
        end_on: "#{TimeKeeper.date_of_record.year}-08-01",
        title: "test title",
        tool_tip: "jhsdjhs",
        pre_event_sep_in_days: "10",
        is_self_attested: true,
        reason: "lost_access_to_mec",
        post_event_sep_in_days: "88",
        market_kind: "individual",
        effective_on_kinds: ["date_of_event"],
        ordinal_position: 1 }
    end

    before  do
      @result = subject.call(contract_params)
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end

    it 'should not have any errors' do
      expect(@result.errors.empty?).to be_truthy
    end
  end

  context 'failure case' do
    let(:contract_params) do
      { start_on: "#{TimeKeeper.date_of_record.year}-08-19",
        end_on: "#{TimeKeeper.date_of_record.year}-07-19",
        title: "test title",
        tool_tip: "jhsdjhs",
        pre_event_sep_in_days: "10",
        is_self_attested: true,
        reason: "lost_access_to_mec",
        post_event_sep_in_days: "88",
        market_kind: "individual",
        effective_on_kinds: ["date_of_event"],
        ordinal_position: 1 }
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
      expect(@result.errors.messages.first.text).to eq('End on must be after start on date')
    end
  end

end
