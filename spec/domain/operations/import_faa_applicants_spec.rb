# frozen_string_literal: true

RSpec.describe Operations::ImportFaaApplicants, type: :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants, family: family) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid application id passed' do
    let(:second_application) { FactoryBot.build(:financial_assistance_application, family: family) }

    it 'should return a failure' do
      result = subject.call(application_id: second_application.id, family_id: family.id)

      expect(result.failure?).to be_truthy
      expect(result.failure).to eq "Unable to find Application with ID #{second_application.id}."
    end
  end

  context 'invalid family id passed' do
    let(:second_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:second_family) { FactoryBot.build(:family, :with_primary_family_member, person: second_person)}

    it 'should return a failure' do
      result = subject.call(application_id: application.id, family_id: second_family.id)

      expect(result.failure?).to be_truthy
      expect(result.failure).to eq "Unable to find Family with ID #{second_family.id}."
    end
  end

  context 'FAA application and family ids mismatching' do
    let(:second_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:second_family) { FactoryBot.create(:family, :with_primary_family_member, person: second_person)}

    it 'should return a failure' do
      result = subject.call(application_id: application.id, family_id: second_family.id)

      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['Application family not matching the family ID passed'])
    end
  end

  context 'FAA application and family passed' do
    subject { Operations::ImportFaaApplicants.new.call(application_id: application.id, family_id: family.id) }

    it 'should return success' do
      expect(subject.success?).to be_truthy
      expect(subject.success.persisted?).to be_truthy
      expect(subject.success).to be_a Family
    end

    it 'should create family members' do
      expect(family.family_members.count).to eq 1
      expect(subject.success.family_members.count).to eq application.applicants.count
    end

    it 'should create person record with associations' do
      updated_family = subject.success
      spouse = application.applicants.detect{|applicant| applicant.relation_with_primary == 'spouse'}
      spouse_person = updated_family.family_members.detect{|fm| fm.primary_relationship == 'spouse'}.person

      expect(spouse_person.ssn).to eq spouse.ssn
      expect(spouse_person.dob).to eq spouse.dob
      expect(spouse_person.consumer_role).to be_present

      expect(spouse_person.addresses.count).to eq spouse.addresses.count
      expect(spouse_person.emails.count).to eq spouse.emails.count
      expect(spouse_person.phones.count).to eq spouse.phones.count
    end

    it 'should update family_member_ids for applicants' do
      subject
      expect(application.reload.applicants.any?{|applicant| applicant.family_member_id.blank?}).to be_falsey
    end
  end

  context 'When Immigration status provided' do

    context 'When Permanent Resident Card selected' do

      let(:immigration_params) do
        {
          vlp_subject: 'I-551 (Permanent Resident Card)',
          alien_number: "974312399",
          card_number: "7478823423442",
          expiration_date: Date.new(2020,10,31)
        }
      end

      let(:spouse) { application.applicants.detect{|applicant| applicant.relation_with_primary == 'spouse' } }

      before do
        spouse.update_attributes(immigration_params)
      end

      subject { Operations::ImportFaaApplicants.new.call(application_id: application.id, family_id: family.id) }

      it 'should create vlp document with subject' do
        updated_family = subject.success
        spouse_person = updated_family.family_members.detect{|fm| fm.primary_relationship == 'spouse'}.person
        consumer_role = spouse_person.consumer_role
        expect(consumer_role).to be_present
        expect(consumer_role.vlp_documents.count).to eq 1
        vlp_document = consumer_role.vlp_documents.first
        immigration_params.each_pair {|attr, value| expect(vlp_document.send(attr)).to eq value }
        expect(consumer_role.active_vlp_document_id).to eq vlp_document.id
      end
    end
  end

  # context 'FAA applicant present on the family and information updated' do

  #   it 'should update the matching family member' do
  #     result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
  #     expect(result.failure).to eq([:danger, 'VLP document type is invalid: test'])
  #   end
  # end

  # context 'Primary applicant information updated' do

  #   it 'should update the primary family member' do
  #     result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
  #     expect(result.failure).to eq([:danger, 'VLP document type is invalid: test'])
  #   end
  # end

  # context 'FAA applicant not matching with information on family' do

  #   it 'should create a new family member' do
  #     result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
  #     expect(result.failure).to eq([:danger, 'VLP document type is invalid: test'])
  #   end
  # end
end
