# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::CreateOrUpdateVlpDocument, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, :with_applicants, family_id: family.id) }
  let(:applicant_params) { application.primary_applicant.attributes.merge(vlp_doc_params) }
  let(:params) { {applicant_params: applicant_params, person: person} }

  describe 'create vlp document' do
    context 'when valid document parameters passed' do

      let(:vlp_doc_params) do
        {
          vlp_subject: 'I-551 (Permanent Resident Card)',
          alien_number: "974312399",
          card_number: "7478823423442",
          expiration_date: Date.new(2020,10,31)
        }
      end

      it 'should return success with vlp document' do
        result = subject.call(params: params)
        
        expect(result.success?).to be_truthy
        expect(result.success).to be_a VlpDocument
        expect(result.success).to eq person.consumer_role.find_document(vlp_doc_params[:vlp_subject])
      end
    end

    context 'when invalid document parameters passed (subject missing)' do

      let(:vlp_doc_params) do
        {
          alien_number: "974312399",
          card_number: "7478823423442",
          expiration_date: Date.new(2020,10,31)
        }
      end

      it 'should return failure' do
        result = subject.call(params: params)
        
        expect(result.failure?).to be_truthy
        expect(result.failure.errors.to_h[:subject]).to eq ["must be filled"]
      end
    end
  end

  describe 'update vlp document' do
    context 'when valid document parameters passed' do

      let(:vlp_doc_params) do
        {
          vlp_subject: 'I-551 (Permanent Resident Card)',
          alien_number: "974312399",
          card_number: "7478823423442",
          expiration_date: Date.new(2020,10,31)
        }
      end

      let!(:vlp_document) do
        document = person.consumer_role.find_document(vlp_doc_params[:vlp_subject])
        document.assign_attributes(alien_number: '111111111', card_number: "7000000000000", expiration_date: TimeKeeper.date_of_record + 1.year)
        document.save
        document
      end

      it 'should return success with updated vlp document' do
        old_document = person.consumer_role.find_document(vlp_doc_params[:vlp_subject])
        expect(old_document.persisted?).to be_truthy
        expect(old_document.alien_number).to eq '111111111'
        expect(old_document.expiration_date).to eq TimeKeeper.date_of_record + 1.year

        result = subject.call(params: params)
        
        expect(result.success?).to be_truthy
        expect(result.success).to be_a VlpDocument
        
        updated_doc = person.consumer_role.find_document(vlp_doc_params[:vlp_subject])
        expect(updated_doc.persisted?).to be_truthy
        expect(updated_doc.alien_number).to eq vlp_doc_params[:alien_number]
        expect(updated_doc.expiration_date).to eq vlp_doc_params[:expiration_date]
      end
    end
  end
end