# frozen_string_literal: true

RSpec.describe Operations::Families::ApplyForFinancialAssistance, type: :model, dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'bad argument' do
    it 'should return failure' do
      expect(subject.call(family_id: 'family_id')).to be_a Dry::Monads::Result::Failure
    end
  end

  context 'with a family' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_ssn) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      @result = subject.call(family_id: family.id)
    end

    it 'should return success' do
      expect(@result).to be_a Dry::Monads::Result::Success
    end

    it 'should match with person hbx_id' do
      expect(@result.success.first[:person_hbx_id]).to eq(person.hbx_id)
    end

    it 'should have all the matching keys' do
      [:person_hbx_id, :is_applying_coverage, :citizen_status, :is_consumer_role,
       :indian_tribe_member, :is_incarcerated, :addresses_attributes,
       :phones_attributes, :emails_attributes, :family_member_id,
       :is_primary_applicant].each do |key|
        expect(@result.success.first.keys).to include(key)
      end
    end
  end
end
