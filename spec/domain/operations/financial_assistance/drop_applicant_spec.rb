# frozen_string_literal: true

RSpec.describe ::Operations::FinancialAssistance::DropApplicant, type: :model, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:person2) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { FactoryBot.create(:family_member, family: family, person: person2, is_active: false) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    before do
      @result = subject.call({test: 'family_member'})
    end

    it 'should return a failure object' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return a failure' do
      expect(@result.failure).to eq('family_member key does not exist')
    end
  end

  context 'valid arguments' do
    before do
      @result = subject.call({family_member: family_member})
    end

    it 'should return a success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end
  end
end
