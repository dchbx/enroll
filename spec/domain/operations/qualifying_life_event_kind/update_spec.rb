# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Update, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let(:qlek) { FactoryBot.create(:qualifying_life_event_kind, title: 'qlek title') }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'for success case' do
    let(:qlek_update_params) do
      { 'start_on' => "#{TimeKeeper.date_of_record.year}-07-01",
        'end_on' => "#{TimeKeeper.date_of_record.year}-08-01",
        'title' => 'test title',
        'tool_tip' => 'jhsdjhs',
        'pre_event_sep_in_days' => '10',
        'is_self_attested' => 'true',
        'reason' => 'lost_access_to_mec',
        'other_reason' => '',
        'post_event_sep_in_days' => '88',
        'market_kind' => 'individual',
        'effective_on_kinds' => ['date_of_event'],
        '_id' => qlek.id.to_s }
    end

    before :each do
      @result = subject.call(qlek_update_params)
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return a qlek object' do
      expect(@result.success).to be_a(::QualifyingLifeEventKind)
    end

    it 'should update QualifyingLifeEventKind object' do
      qlek.reload
      expect(qlek.title).to eq(qlek_update_params['title'])
    end
  end

  context 'for failure case' do

    let(:qlek_update_params) do
      { 'start_on' => "#{TimeKeeper.date_of_record.year}-08-19",
        'end_on' => "#{TimeKeeper.date_of_record.year}-07-19",
        'title' => 'test title',
        'tool_tip' => 'jhsdjhs',
        'pre_event_sep_in_days' => '10',
        'is_self_attested' => 'true',
        'reason' => 'lost_access_to_mec',
        'post_event_sep_in_days' => '88',
        'market_kind' => 'individual',
        'effective_on_kinds' => ['date_of_event'],
        '_id' => qlek.id.to_s }
    end

    before :each do
      @result = subject.call(qlek_update_params)
      qlek.reload
    end

    it 'should return failure' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return error message' do
      expect(@result.failure[1]).to eq(['End on must be after start on date'])
    end

    it 'should not update any QualifyingLifeEventKind object' do
      expect(qlek.title).not_to eq(qlek_update_params['title'])
    end
  end
end
