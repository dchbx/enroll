# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Entities::QualifyingLifeEventKind, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  describe 'with valid arguments' do
    let(:input_params) do
      { :start_on => TimeKeeper.date_of_record,
        :end_on => (TimeKeeper.date_of_record + 25.days),
        :title => 'A new SEP Type',
        :tool_tip => 'test tool tip',
        :pre_event_sep_in_days => 4,
        :is_self_attested => true,
        :reason => 'lost_access_to_mec',
        :post_event_sep_in_days => 7,
        :market_kind => 'individual',
        :effective_on_kinds => ['date_of_event'],
        :ordinal_position => 1,
        coverage_effective_on: TimeKeeper.date_of_record,
        coverage_start_on: TimeKeeper.date_of_record,
        coverage_end_on: (TimeKeeper.date_of_record + 25.days),
        event_kind_label: 'event kind label',
        is_visible: true,
        termination_on_kinds: [],
        date_options_available: true }
    end

    it 'should initialize' do
      expect(::Entities::QualifyingLifeEventKind.new(input_params)).to be_a ::Entities::QualifyingLifeEventKind
    end

    it 'should not raise error' do
      expect { ::Entities::QualifyingLifeEventKind.new(input_params) }.not_to raise_error
    end

    context 'for end_on as optional' do
      before do
        input_params.merge!({end_on: nil})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end

    context 'for end_on as optional' do
      before do
        input_params.merge!({end_on: nil})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end

    context 'for tool_tip as optional' do
      before do
        input_params.merge!({tool_tip: nil})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end

    context 'for coverage_start_on as optional' do
      before do
        input_params.merge!({coverage_start_on: nil})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end

    context 'for coverage_end_on as optional' do
      before do
        input_params.merge!({coverage_end_on: nil})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end

    context 'for termination_on_kinds as empty' do
      before do
        input_params.merge!({termination_on_kinds: []})
        @result = ::Entities::QualifyingLifeEventKind.new(input_params)
      end

      it 'should initialize the entity' do
        expect(@result).to be_a Entities::QualifyingLifeEventKind
      end
    end
  end

  describe 'with invalid arguments' do
    it 'should raise error' do
      expect { subject }.to raise_error(Dry::Struct::Error, /:start_on is missing in Hash input/)
    end
  end
end
