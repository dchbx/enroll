RSpec.shared_examples 'setup basic models' do
  let!(:primary_person) {FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: primary_person)}
  let!(:household) {family.households.first}
  let!(:tax_household) {FactoryGirl.create(:tax_household, household: household)}
  let!(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household)}
  let(:address) {FactoryGirl.build(:address)}
  let(:phone) {FactoryGirl.build(:phone)}
end

RSpec.shared_examples 'submitted application with one member and one applicant' do
  include_examples 'setup basic models'

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow_any_instance_of(FinancialAssistance::Application).to receive(:create_verification_documents).and_return(true)
  end

  let!(:application) {FactoryGirl.create(:application, family: family)}
  let!(:applicant1) {FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family.primary_applicant.id)}
  let!(:income) {FactoryGirl.create(:financial_assistance_income, applicant: applicant1, employer_address: address, employer_phone: phone)}
  let!(:benefit) {FactoryGirl.create(:financial_assistance_benefit, applicant: applicant1, employer_address: address, employer_phone: phone)}
  let!(:deduction) {FactoryGirl.create(:financial_assistance_deduction, applicant: applicant1)}
  let!(:verification_type) {FactoryGirl.create(:verification_type, applicant: applicant1, type_name: 'MEC', validation_status: 'verified')}
end

RSpec.shared_examples 'submitted application with two active members and one applicant' do
  include_examples 'submitted application with one member and one applicant'

  let!(:person2) {FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family_member1) {FactoryGirl.create(:family_member, family: family, person: person2)}
end

RSpec.shared_examples 'submitted application with two active members and two applicants' do
  include_examples 'submitted application with two active members and one applicant'

  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member1.id, is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id) }
end

# this example has one submitted application with one active member and two applicant
RSpec.shared_examples 'submitted application with one active member and two applicant' do
  include_examples 'submitted application with one member and one applicant'

  let!(:person2) {FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family_member1) {FactoryGirl.create(:family_member, family: family, person: person2, is_active: false)}
  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member1.id) }
end

RSpec.shared_examples 'draft application with 2 applicants' do
  include_examples 'setup basic models'

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    primary_person.add_relationship(second_person, "spouse", family.id)
    primary_person.add_relationship(third_person, "child", family.id)
  end

  let!(:second_person) {FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:second_family_member) {FactoryGirl.create(:family_member, family: family, person: second_person, is_active: true)}
  let!(:third_person) {FactoryGirl.create(:person, :with_consumer_role)}
  let!(:family_member_not_on_application) {FactoryGirl.create(:family_member, family: family, person: third_person, is_active: true)}
  let!(:application) {FactoryGirl.create(:application, aasm_state: 'draft', family: family)}
  let!(:first_applicant) {FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family.primary_applicant.id)}
  let!(:second_applicant) { FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: second_family_member.id) }

end

