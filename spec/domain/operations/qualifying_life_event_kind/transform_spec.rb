# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Transform, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:qlek) { FactoryBot.create(:qualifying_life_event_kind, is_active: true) }

  context 'for failure case' do
    context 'no end date' do
      before :each do
        qlek.update_attributes!(start_on: TimeKeeper.date_of_record - 20.days)
        @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: ''})
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure message' do
        expect(@result.failure).to eq([qlek, 'Invalid Date: '])
      end
    end

    context 'no start date' do
      before :each do
        @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: (TimeKeeper.date_of_record - 20.days).strftime("%Y-%m-%d")})
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure message' do
        expect(@result.failure).to eq([qlek, 'Start on cannot be empty'])
      end
    end

    context 'end date before start on' do
      before :each do
        qlek.update_attributes!(aasm_state: :active,
                                start_on: (TimeKeeper.date_of_record - 10.days),
                                end_on: (TimeKeeper.date_of_record - 9.days))
        @end_on = TimeKeeper.date_of_record - 20.days
        @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: @end_on.strftime("%Y-%m-%d")})
        qlek.reload
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure message' do
        expect(@result.failure).to eq([qlek, "End on: #{@end_on} must be after start on date"])
      end
    end

    context 'with past end date' do
      before :each do
        qlek.update_attributes!(aasm_state: :active,
                                start_on: (TimeKeeper.date_of_record - 10.days),
                                end_on: (TimeKeeper.date_of_record - 4.days))
        @end_on = TimeKeeper.date_of_record - 3.days
        @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: @end_on.strftime("%Y-%m-%d")})
        qlek.reload
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure message' do
        expect(@result.failure).to eq([qlek, "End on: Expiration date must be on or after #{TimeKeeper.date_of_record - 1.day}"])
      end
    end

    context 'end date overlaps with active SEP' do
      let!(:qlek2) { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month, is_active: true) }
      before :each do
        qlek.update_attributes!(aasm_state: :active,
                                start_on: TimeKeeper.date_of_record.beginning_of_month,
                                end_on: TimeKeeper.date_of_record.end_of_month)
        @end_on = TimeKeeper.date_of_record.next_month.beginning_of_month
        @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: @end_on.strftime("%Y-%m-%d")})
        qlek.reload
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure message' do
        expect(@result.failure).to eq([qlek, "End on: Expiration date overlaps with Active SEP Type. Expiration date must be on or before #{qlek2.start_on - 1.day}"])
      end
    end
  end

  context 'for expired case with future date' do
    before :each do
      qlek.update_attributes!(aasm_state: :active,
                              start_on: (TimeKeeper.date_of_record - 30.days),
                              end_on: (TimeKeeper.date_of_record - 10.days))
      @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: (TimeKeeper.date_of_record + 20.days).strftime("%Y-%m-%d")})
      qlek.reload
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return qlek object' do
      expect(@result.success).to eq([qlek, 'expire_pending_success'])
    end

    it 'should expire the qlek object' do
      expect(qlek.aasm_state).to eq(:expire_pending)
    end
  end

  context 'for expire case with current date' do
    before :each do
      qlek.update_attributes!(aasm_state: :active,
                              start_on: (TimeKeeper.date_of_record - 30.days),
                              end_on: (TimeKeeper.date_of_record - 10.days))
      @result = subject.call(params: {qle_id: qlek.id.to_s, end_on: TimeKeeper.date_of_record.strftime("%Y-%m-%d")})
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

  context 'for expire case with current date - 1.day' do
    let(:user) {FactoryBot.create(:user)}
    before :each do
      qlek.update_attributes!(aasm_state: :active,
                              start_on: (TimeKeeper.date_of_record - 30.days),
                              end_on: (TimeKeeper.date_of_record - 10.days))
      @result = subject.call(params: {qle_id: qlek.id.to_s, updated_by: user.id, end_on: (TimeKeeper.date_of_record - 1.day).strftime("%Y-%m-%d")})
      qlek.reload
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return qlek object' do
      expect(@result.success).to eq([qlek, 'expire_success'])
    end

    it 'should tranform the qlek object to expired state' do
      expect(qlek.aasm_state).to eq(:expired)
    end

    it 'should set updated by id' do
      expect(qlek.updated_by).to eq user.id
    end

  end
end
