# frozen_string_literal: true

RSpec.shared_context 'setup initial family with one member', :shared_context => :metadata do
  let(:person_dob_year) { Date.today.year - 48 }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: Date.new(person_dob_year, 4, 4)) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.primary_applicant }
end

RSpec.shared_context 'setup one tax household with one ia member', :shared_context => :metadata do
  include_context 'setup initial family with one member'

  let!(:person2) do
    member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (person.dob - 10.years))
    person.ensure_relationship_with(member, 'spouse')
    member.save!
    member
  end

  let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }

  let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
  let!(:tax_household_member) { FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household) }
  let!(:eligibilty_determination) { FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73') }
end

RSpec.shared_context 'setup two tax households with one ia member each', :shared_context => :metadata do
  include_context 'setup one tax household with one ia member'

  let!(:tax_household2) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
  let!(:tax_household_member2) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: tax_household2) }
  let!(:eligibilty_determination2) { FactoryBot.create(:eligibility_determination, max_aptc: 250.00, tax_household: tax_household2, csr_eligibility_kind: 'csr_87') }
end

RSpec.shared_context 'setup initial family with primary and spouse', :shared_context => :metadata do
  include_context 'setup initial family with one member'

  let!(:person2) do
    member = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, dob: (person.dob - 10.years))
    person.ensure_relationship_with(member, 'spouse')
    member.save!
    member
  end

  let!(:family_member2) { FactoryBot.create(:family_member, family: family, person: person2) }
end

RSpec.shared_context 'setup one tax household with two ia members', :shared_context => :metadata do
  include_context 'setup initial family with primary and spouse'

  let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
  let!(:tax_household_member) { FactoryBot.create(:tax_household_member, applicant_id: family_member.id, tax_household: tax_household) }
  let!(:eligibilty_determination) { FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household) }
  let!(:tax_household_member2) { FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household) }
end

RSpec.shared_context 'setup one tax household with one ia member and one medicaid member', :shared_context => :metadata do
  include_context 'setup one tax household with two ia members'

  tax_household_member2.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
end
