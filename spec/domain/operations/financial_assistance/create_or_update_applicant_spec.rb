# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::FinancialAssistance::CreateOrUpdateApplicant, type: :model, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'test10', last_name: 'test30', gender: 'male') }
  let!(:person2) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'test', last_name: 'test10', gender: 'male') }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { FactoryBot.create(:family_member, family: family, person: person2) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    before do
      @result = subject.call({event: :family_member_created, test: 'family_member'})
    end

    it 'should return a failure object' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return a failure' do
      expect(@result.failure).to eq('Missing keys')
    end
  end

  context 'valid arguments' do
    before do
      @result = subject.call({event: :family_member_created, family_member: family_member})
    end

    it 'should return a success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return success with a message' do
      expect(@result.success).to eq('A successful call was made to FAA engine to create or update an applicant')
    end
  end

  context 'for call backs' do
    context 'for stack level too deep' do
      it 'should not raise error' do
        expect{create_data_for_call_backs}.not_to raise_error(SystemStackError)
      end
    end

    context 'for creation of objects' do
      before do
        create_data_for_call_backs
      end

      it 'should return 3 family members for the family' do
        expect(@family10.reload.family_members.count).to eq(3)
      end

      it 'should return 3 applicants for the draft application' do
        expect(@application10.reload.applicants.count).to eq(3)
      end
    end
  end
end

def create_data_for_call_backs
  person10 = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, is_incarcerated: false)
  @family10 = FactoryBot.create(:family, :with_primary_family_member, person: person10)
  @application10 = FactoryBot.create(:financial_assistance_application, family_id: @family10.id, aasm_state: 'draft')
  applicant10 = FactoryBot.create(:financial_assistance_applicant, :with_work_phone, :with_work_email,
                                  :with_home_address, family_member_id: @family10.primary_applicant.id,
                                  application: @application10, gender: person10.gender, is_incarcerated: person10.is_incarcerated,
                                  ssn: person10.ssn, dob: person10.dob, first_name: person10.first_name,
                                  last_name: person10.last_name, is_primary_applicant: true, person_hbx_id: person10.hbx_id,
                                  is_applying_coverage: true, citizen_status: 'us_citizen', indian_tribe_member: false)

  person2 = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, is_incarcerated: false)
  person10.ensure_relationship_with(person2, 'child')
  # Should trigger creation of an Applicant2 matching the Dependent FamilyMember2.
  family_member2 = FactoryBot.create(:family_member, is_active: true, family: @family10, person: person2)
  applicant3 = FactoryBot.create(:financial_assistance_applicant, :with_work_phone, :with_work_email, :with_home_address, :with_ssn,
                                 is_consumer_role: true, application: @application10, gender: 'male', is_incarcerated: false,
                                 dob: TimeKeeper.date_of_record, first_name: 'first', last_name: 'last', is_primary_applicant: false,
                                 is_applying_coverage: false, citizen_status: 'us_citizen')
  # Should trigger creation of an FamilyMember3 matching the Applicant3.
  @application10.ensure_relationship_with_primary(applicant3, 'child')
  @family10.save!
  @application10.save!
end
