# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Create, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'for success case' do

    let(:qlek_create_params) do
      { start_on: "#{TimeKeeper.date_of_record.year}-07-01",
        end_on: "#{TimeKeeper.date_of_record.year}-08-01",
        title: 'test title',
        tool_tip: 'jhsdjhs',
        pre_event_sep_in_days: '10',
        is_self_attested: 'true',
        reason: 'lost_access_to_mec',
        post_event_sep_in_days: '88',
        market_kind: 'individual',
        effective_on_kinds: ['date_of_event'] }
    end

    before :each do
      @result = subject.call(qlek_create_params)
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return a qlek object' do
      expect(@result.success).to be_a(::QualifyingLifeEventKind)
    end

    it 'should create QualifyingLifeEventKind object' do
      expect(::QualifyingLifeEventKind.all.count).to eq(1)
    end
  end

  context 'for failure case' do

    let(:qlek_create_params) do
      { start_on: "#{TimeKeeper.date_of_record.year}-08-19",
        end_on: "#{TimeKeeper.date_of_record.year}-07-19",
        title: 'test title',
        tool_tip: 'jhsdjhs',
        pre_event_sep_in_days: '10',
        is_self_attested: 'true',
        reason: 'lost_access_to_mec',
        post_event_sep_in_days: '88',
        market_kind: 'individual',
        effective_on_kinds: ['date_of_event'] }
    end

    before :each do
      @result = subject.call(qlek_create_params)
    end

    it 'should return failure' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return error message' do
      expect(@result.failure[1]).to eq(['End on must be after start on date'])
    end

    it 'should not create any QualifyingLifeEventKind objects' do
      expect(::QualifyingLifeEventKind.all.count).to be_zero
    end
  end
end
