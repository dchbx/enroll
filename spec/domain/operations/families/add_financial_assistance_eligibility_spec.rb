# frozen_string_literal: true

RSpec.describe Operations::Families::AddFinancialAssistanceEligibility, type: :model, dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'success' do
    let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product) }
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:person) do
      FactoryBot.create(:person,
                        :with_consumer_role,
                        :with_active_consumer_role,
                        hbx_id: '20944967',
                        last_name: 'Test',
                        first_name: 'Domtest34',
                        ssn: '243108282',
                        dob: Date.new(1984, 3, 8))
    end
    let(:xml) { File.read(Rails.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family.xml')) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:application) do
      FactoryBot.create(:financial_assistance_application,
                        family: family,
                        eligibility_response_payload: xml)
    end
    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        first_name: person.first_name,
                        last_name: person.last_name,
                        dob: person.dob)
    end

    before do
      bcp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      bcp.update_attributes!(slcsp_id: product.id)
      @result = subject.call(application: application)
      family.reload
      @thhs = family.active_household.tax_households
    end

    it 'should return success' do
      expect(@result).to be_a Dry::Monads::Result::Success
    end

    it 'should create Tax Household object' do
      expect(@thhs.count).to eq(1)
    end

    it 'should create Tax Household Member object' do
      expect(@thhs.first.tax_household_members.first.applicant_id).to eq(family.primary_applicant.id)
    end

    it 'should create Eligibility Determination object' do
      expect(@thhs.first.latest_eligibility_determination.max_aptc.to_f).to eq(47.78)
    end
  end
end
