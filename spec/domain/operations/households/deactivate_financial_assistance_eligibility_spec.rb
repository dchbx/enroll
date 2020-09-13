# frozen_string_literal: true

RSpec.describe Operations::Households::DeactivateFinancialAssistanceEligibility, type: :model, dbclean: :after_each do
  let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
  let(:family2) {FactoryBot.create(:family, :with_primary_family_member)}
  let(:household) {FactoryBot.create(:household, family: family)}
  let(:tax_household) {FactoryBot.create(:tax_household, household: household)}
  let(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10, effective_starting_on: Date.new(2020, 1, 1), effective_ending_on: nil)}

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    it 'should return a failure' do
      result = subject.call(family_id: 'family_id', date: Date.new(2020, 1, 1))
      expect(result.failure).to eq('Unable to find family with ID family_id')
    end
  end

  context 'no tax_households' do
    it 'should return a failure' do
      result = subject.call(family_id: family2.id, date: Date.new(2020, 1, 1))
      expect(result.failure).to eq('Unable to find active tax_households')
    end
  end

  context 'update tax households' do
    it 'should success for update' do
      result = subject.call(family_id: family.id, date: Date.new(2020, 1, 1))
      expect(result.success).to eq(nil)
    end
  end
end
