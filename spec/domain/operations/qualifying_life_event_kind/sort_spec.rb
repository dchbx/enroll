# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::QualifyingLifeEventKind::Sort, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:qlek1) { FactoryBot.create(:qualifying_life_event_kind, ordinal_position: 1, is_active: true) }
  let!(:qlek2) { FactoryBot.create(:qualifying_life_event_kind, ordinal_position: 2, is_active: true) }

  let!(:input_params) do
    { 'market_kind' => 'shop',
      'sort_data'=> [
        {'id' => qlek2.id.to_s, 'position'=>1},
        {'id' => qlek1.id.to_s, 'position'=>2}]}
  end

  context 'update ordinal_position' do
    before :each do
      @result = subject.call(params: input_params)
      qlek1.reload
      qlek2.reload
    end

    it 'should return success' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should update ordinal_positions of qlek objects' do
      expect(qlek1.ordinal_position).to eq(2)
      expect(qlek2.ordinal_position).to eq(1)
    end
  end
end
