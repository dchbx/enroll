# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::DropFamilyMember, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants, family_id: family.id) }
  let(:applicant) { application.active_applicants.last }
  let(:applicant_person) { FactoryBot.create(:person, first_name: applicant.first_name, last_name: applicant.last_name, dob: applicant.dob, ssn: applicant.ssn, gender: applicant.gender) }
  let(:applicant_family_member) do
    family_member = family.relate_new_member(applicant_person, applicant.relation_with_primary)
    family.save!
    family_member
  end

  let(:params) { {family_id: family.id, family_member_id: applicant_family_member.id} }

  describe 'drop family member' do
    context 'when family member and family ids passed' do

      it 'should return success and drop family member' do
        expect(applicant_family_member.is_active).to be_truthy
        result = subject.call(params: params)
        expect(result).to be_a(Dry::Monads::Result::Success)
        applicant_family_member.reload
        expect(applicant_family_member.is_active).to be_falsey
      end
    end

    context 'when invalid params passed' do
      let(:second_person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'fredrick', last_name: 'homes', dob: 41.years.ago, ssn: '472740042') }
      let(:second_family) { FactoryBot.create(:family, :with_primary_family_member, person: second_person)}
      let(:params) { {family_id: second_family.id, family_member_id: applicant_family_member.id} }

      it 'should return success with vlp document' do
        result = subject.call(params: params)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq "Family and family member Id's does not match"
      end
    end
  end
end