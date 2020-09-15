# frozen_string_literal: true

RSpec.describe Operations::FinancialAssistance::ParseApplicant, type: :model, dbclean: :after_each do
  let!(:person)        { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family)        { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.family_members[0] }
  let!(:hbx_profile)   { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:product)        { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product) }

  before :each do
    bcp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
    bcp.update_attributes!(slcsp_id: product.id)
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    it 'should return a failure' do
      result = subject.call({family_member: 'family_member'})
      expect(result.failure).to eq('Given family member is not a valid object')
    end
  end

  context 'with valid arguments' do

    let(:result)  { subject.call({family_member: family_member}) }

    it 'should return applicant hash' do
      expect(result.success.is_a?(Hash)).to be_truthy
    end

    it 'should return hash with member hbx_id' do
      expect(result.success[:person_hbx_id]).to eq person.hbx_id
    end

    it 'should return hash with member hbx_id' do
      expect(result.success[:ssn]).to eq person.ssn
    end

    it 'should return hash with member dob' do
      expect(result.success[:dob]).to eq person.dob.to_s
    end
  end

end
