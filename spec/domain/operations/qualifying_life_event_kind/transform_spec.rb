# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Transform, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:qlek) { FactoryBot.create(:qualifying_life_event_kind, is_active: true) }

  context 'for expired case' do
    before :each do
      qlek.update_attributes!(aasm_state: :active,
                              start_on: (TimeKeeper.date_of_record - 30.days),
                              end_on: (TimeKeeper.date_of_record - 10.days))
      @result = subject.call({qle_id: qlek.id.to_s, end_on: (TimeKeeper.date_of_record - 20.days).to_s})
      qlek.reload
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return qlek object' do
      expect(@result.success).to eq([qlek, 'expire_success'])
    end

    it 'should expire the qlek object' do
      expect(qlek.aasm_state).to eq(:expired)
    end
  end

  context 'for expire pending case' do
    before :each do
      qlek.update_attributes!(aasm_state: :active,
                              start_on: (TimeKeeper.date_of_record - 30.days),
                              end_on: (TimeKeeper.date_of_record - 10.days))
      @result = subject.call({qle_id: qlek.id.to_s, end_on: TimeKeeper.date_of_record.to_s})
      qlek.reload
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return qlek object' do
      expect(@result.success).to eq([qlek, 'expire_pending_success'])
    end

    it 'should tranform the qlek object to expire_pending state' do
      expect(qlek.aasm_state).to eq(:expire_pending)
    end
  end
end
