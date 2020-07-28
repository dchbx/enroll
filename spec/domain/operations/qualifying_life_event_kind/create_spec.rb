# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Create, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  context "create QualifyingLifeEventKind" do

    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
    end

    context 'for success case' do

      let(:qlek_create_params) do
        { 'start_on': "#{TimeKeeper.date_of_record.year}-07-01",
          'end_on': "#{TimeKeeper.date_of_record.year}-08-01",
          'title': 'test title',
          'tool_tip': 'test tooltip',
          'pre_event_sep_in_days': '10',
          'is_self_attested': 'true',
          'reason': 'lost_access_to_mec',
          'post_event_sep_in_days': '88',
          'market_kind': 'individual',
          'effective_on_kinds': ['date_of_event'],
          'coverage_effective_on': "#{TimeKeeper.date_of_record.year}-07-01",
          'coverage_end_on': "#{TimeKeeper.date_of_record.year}-08-01",
          'event_kind_label': 'event kind label',
          'is_visible': true,
          'date_options_available': true }

      end

      context 'without publish' do
        before :each do
          @result = subject.call(params: qlek_create_params)
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

      context 'for publish' do
        context 'for success case', :dbclean => :after_each do
          before :each do
            qlek_create_params.merge!({'publish': 'Publish'})
            @result = subject.call(params: qlek_create_params)
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

          it 'should publish the newly created qlek object' do
            expect(QualifyingLifeEventKind.all.first.active?).to be_truthy
          end
        end

        context 'for failure case', :dbclean => :after_each do
          let!(:q1) {FactoryBot.create(:qualifying_life_event_kind, market_kind: 'individual', reason: 'lost_access_to_mec', aasm_state: :active, is_active: true)}
          let!(:q2) {FactoryBot.create(:qualifying_life_event_kind, title: 'test title', market_kind: 'individual', reason: 'lost_access_to_mec', aasm_state: :draft, is_active: false)}

          let(:qlek_publish_params) do
            { 'start_on': "#{TimeKeeper.date_of_record.year}-07-01",
              'end_on': "#{TimeKeeper.date_of_record.year}-08-01",
              'title': 'test title',
              'tool_tip': 'test tooltip',
              'pre_event_sep_in_days': '10',
              'is_self_attested': 'true',
              'reason': q2.reason,
              'post_event_sep_in_days': '88',
              'market_kind': 'individual',
              'effective_on_kinds': ['date_of_event'],
              'coverage_effective_on': "#{TimeKeeper.date_of_record.year}-07-01",
              'coverage_end_on': "#{TimeKeeper.date_of_record.year}-08-01",
              'event_kind_label': 'event kind label',
              'is_visible': true,
              'id': q2.id.to_s,
              'publish': 'Publish',
              'date_options_available': true }
          end

          before do
            @result = subject.call(params: qlek_publish_params)
          end

          it 'should return failure' do
            expect(@result).to be_a(Dry::Monads::Result::Failure)
          end

          it 'should return error message' do
            expect(@result.failure[1]).to eq(['Active SEP type exists with same reason'])
          end

          it 'should not publish qlek objects' do
            expect(::QualifyingLifeEventKind.where(title: 'test title').first.aasm_state).to eq :draft
          end
        end
      end
    end

    context 'for failure case' do

      let(:qlek_create_params) do
        { start_on: "#{TimeKeeper.date_of_record.year}-08-19",
          end_on: "#{TimeKeeper.date_of_record.year}-07-19",
          title: 'test title',
          tool_tip: 'test tool tip',
          pre_event_sep_in_days: '10',
          is_self_attested: 'true',
          reason: 'lost_access_to_mec',
          post_event_sep_in_days: '88',
          market_kind: 'individual',
          effective_on_kinds: ['date_of_event'],
          coverage_effective_on: "#{TimeKeeper.date_of_record.year}-07-19",
          coverage_end_on: "#{TimeKeeper.date_of_record.year}-08-01",
          event_kind_label: 'event kind label',
          is_visible: true,
          date_options_available: true }
      end

      before :each do
        @result = subject.call(params: qlek_create_params)
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

  context "update QualifyingLifeEventKind" do

    let(:qlek) { FactoryBot.create(:qualifying_life_event_kind, title: 'qlek title') }

    it 'should be a container-ready operation' do
      expect(subject.respond_to?(:call)).to be_truthy
    end

    context 'for success case' do
      let(:qlek_update_params) do
        { 'start_on' => "#{TimeKeeper.date_of_record.year}-07-01",
          'end_on' => "#{TimeKeeper.date_of_record.year}-08-01",
          'title' => 'test title',
          'tool_tip' => 'test tool tip 2',
          'pre_event_sep_in_days' => '10',
          'is_self_attested' => 'true',
          'reason' => 'lost_access_to_mec',
          'other_reason' => '',
          'post_event_sep_in_days' => '88',
          'market_kind' => 'individual',
          'effective_on_kinds' => ['date_of_event'],
          '_id' => qlek.id.to_s,
          'coverage_effective_on' => "#{TimeKeeper.date_of_record.year}-07-01",
          'coverage_end_on' => "#{TimeKeeper.date_of_record.year}-08-01",
          'event_kind_label' => 'event kind label',
          'is_visible' => true,
          'date_options_available' => true }
      end

      before :each do
        @result = subject.call(params: qlek_update_params)
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
          'tool_tip' => 'test tool tip 3',
          'pre_event_sep_in_days' => '10',
          'is_self_attested' => 'true',
          'reason' => 'lost_access_to_mec',
          'post_event_sep_in_days' => '88',
          'market_kind' => 'individual',
          'effective_on_kinds' => ['date_of_event'],
          '_id' => qlek.id.to_s,
          'coverage_effective_on' => "#{TimeKeeper.date_of_record.year}-07-01",
          'coverage_end_on' => "#{TimeKeeper.date_of_record.year}-08-01",
          'event_kind_label' => 'event kind label',
          'is_visible' => true,
          'date_options_available' => true }
      end

      before :each do
        @result = subject.call(params: qlek_update_params)
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
end
