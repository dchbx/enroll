require 'rails_helper'

class FakesController < ApplicationController
  include ::VlpDoc
end

describe FakesController do
  let(:consumer_role) { FactoryBot.build(:consumer_role) }
  let(:params) { { consumer_role: { vlp_documents_attributes: { "0" => { expiration_date: "06/23/2016", 'sevis_id' => '' }}}, naturalized_citizen: false, eligible_immigration_status: false } }
  let(:person_params) { ActionController::Parameters.new({person: params }) }
  let(:dependent_params) { ActionController::Parameters.new({dependent: params }) }

  context "documents updating" do
    shared_examples_for "updating consumer documents" do |params|
      let(:person_kind) { params.split("_").first.to_sym }
      before :each do
        subject.instance_variable_set("@params", send(params))
        allow(subject).to receive(:params).and_return(send(params))
      end

      it "should convert the date string to dateTime instance" do
        expect(subject.params[person_kind][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date]).to be_a(String)
        expect(subject.update_vlp_documents(consumer_role, person_kind))
        expect(subject.params[person_kind][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date]).to be_a(DateTime)
      end

      context 'active_vlp_document_id' do
        before :each do
          subject.update_vlp_documents(consumer_role, person_kind)
        end

        it 'should return a value which is a bson object' do
          expect(consumer_role.active_vlp_document_id).to be_a BSON::ObjectId
        end
      end
    end

    it_behaves_like "updating consumer documents", "person_params"
    it_behaves_like "updating consumer documents", "dependent_params"
  end

  context "#get_vlp_doc_subject_by_consumer_role" do
    let(:vlp_doc_naturalized) { FactoryBot.build(:vlp_document, :subject => "Certificate of Citizenship" ) }
    let(:vlp_doc_immigrant) { FactoryBot.build(:vlp_document, :subject => "I-327 (Reentry Permit)" ) }
    shared_examples_for "returns vlp document subject" do |doc_subject, citizen_status|
      before do
        consumer_role.vlp_documents = [vlp_doc_naturalized, vlp_doc_immigrant]
      end
      describe "#{citizen_status}" do
        before do
          consumer_role.vlp_documents = []
          consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :subject => doc_subject)
          consumer_role.citizen_status = citizen_status
          consumer_role.active_vlp_document_id = consumer_role.vlp_documents.first.id
        end
        it "returns nil if no consumer role" do
          expect(subject.get_vlp_doc_subject_by_consumer_role(nil)).to be_nil
        end
        it "returns #{doc_subject}" do
          expect(subject.get_vlp_doc_subject_by_consumer_role(consumer_role)).to eq doc_subject
        end
      end
    end

    naturalized_citizen_docs = ["Certificate of Citizenship", "Naturalization Certificate"]

    naturalized_citizen_docs.each do |document|
      it_behaves_like "returns vlp document subject", document, "naturalized_citizen"
    end

    VlpDocument::VLP_DOCUMENT_KINDS.each do |document|
      it_behaves_like "returns vlp document subject", document, "eligible_immigration_status"
    end

    context 'get_vlp_doc_subject_by_consumer_role' do
      before :each do
        vlp_doc1 = FactoryBot.build(:vlp_document, updated_at: TimeKeeper.date_of_record)
        vlp_doc2 = FactoryBot.build(:vlp_document, :subject => 'I-551 (Permanent Resident Card)', updated_at: (TimeKeeper.date_of_record + 1.day))
        consumer_role.vlp_documents = [vlp_doc1, vlp_doc2]
        consumer_role.save!
        consumer_role.update_attributes!(active_vlp_document_id: consumer_role.vlp_documents.first.id)
      end

      it 'should return vlp document which is active and not the one which has the latest updated at' do
        expect(subject.get_vlp_doc_subject_by_consumer_role(consumer_role)).to eq 'I-327 (Reentry Permit)'
      end

      it 'should not return vlp document which has the latest updated at' do
        expect(subject.get_vlp_doc_subject_by_consumer_role(consumer_role)).not_to eq consumer_role.vlp_documents.order_by(:updated_at => 'desc').first.subject
      end
    end
  end

  context "#sensitive_info_changed?" do

    let(:person_params) { { person:  { is_homeless: "true" } } }
    let(:params) { ActionController::Parameters.new(person_params)}

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :is_homeless => false)}

    before do
      allow(subject).to receive(:params).and_return params
    end

    it "should return true for info_changed if sensitive_information changed" do
      allow(person.consumer_role).to receive(:sensitive_information_changed?).with(person_params[:person]).and_return true
      expect(subject.sensitive_info_changed?(person.consumer_role)[0]).to eq true
    end

    it "should return false for info_changed if sensitive_information not changed" do
      allow(person.consumer_role).to receive(:sensitive_information_changed?).with(person_params[:person]).and_return false
      expect(subject.sensitive_info_changed?(person.consumer_role)[0]).to eq false
    end

    it "should return false as dc_status if the past addreess is in dc" do
      expect(subject.sensitive_info_changed?(person.consumer_role)[1]).to eq false
    end

    it "should return true as dc_status if the past addreess is in non-dc" do
      person.update_attributes(is_homeless: true)
      expect(subject.sensitive_info_changed?(person.consumer_role)[1]).to eq true
    end
  end

  context '#validate_vlp_params' do
    context 'for primary' do
      let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

      context 'invalid case' do
        let(:invalid_params) do
          {
            'person' => {
              'consumer_role' => {
                'vlp_documents_attributes' => {
                  '0' => {
                    'subject' => 'Other (With Alien Number)',
                    'alien_number' => '123456789',
                    'passport_number' => 'Jsdhf73',
                    'sevis_id' => '1234567891',
                    'expiration_date' => '02/29/2020',
                    'country_of_citizenship' => 'Algeria',
                    'card_number' => ''
                  }
                }
              }
            }
          }
        end

        let(:params) { ActionController::Parameters.new(invalid_params)}

        before do
          subject.validate_vlp_params(params, 'person', person.consumer_role, nil)
        end

        it 'should add errors to the object if params are invalid' do
          expect(person.errors.full_messages).to eq(['Please fill in your information for Document Description.'])
        end
      end

      context 'valid case' do
        let(:valid_params) do
          {
            'person' => {
              'consumer_role' => {
                'vlp_documents_attributes' => {
                  '0' => {
                    'subject' => 'Other (With Alien Number)',
                    'alien_number' => '123456789',
                    'passport_number' => 'Jsdhf73',
                    'sevis_id' => '1234567891',
                    'expiration_date' => '02/29/2020',
                    'country_of_citizenship' => 'Algeria',
                    'description' => 'Some type of document',
                    'card_number' => ''
                  }
                }
              }
            }
          }
        end

        let(:params) { ActionController::Parameters.new(valid_params)}

        before do
          subject.validate_vlp_params(params, 'person', person.consumer_role, nil)
        end

        it 'should not add any errors to the object if params are valid' do
          expect(person.errors.full_messages).to be_empty
        end
      end
    end

    context 'for dependet' do
      let(:dependent) { ::Forms::FamilyMember.new }

      context 'invalid case' do
        let(:invalid_params) do
          {
            'dependent' => {
              'consumer_role' => {
                'vlp_documents_attributes' => {
                  '0' => {
                    'subject' => 'Other (With Alien Number)',
                    'alien_number' => '123456789',
                    'passport_number' => 'Jsdhf73',
                    'sevis_id' => '1234567891',
                    'expiration_date' => '02/29/2020',
                    'country_of_citizenship' => 'Algeria'
                  }
                }
              }
            }
          }
        end

        let(:params) { ActionController::Parameters.new(invalid_params)}

        before do
          subject.validate_vlp_params(params, 'dependent', nil, dependent)
        end

        it 'should add errors to the object if params are invalid' do
          expect(dependent.errors.full_messages).to eq(['Please fill in your information for Document Description.'])
        end
      end

      context 'valid case' do
        let(:valid_params) do
          {
            'dependent' => {
              'consumer_role' => {
                'vlp_documents_attributes' => {
                  '0' => {
                    'subject' => 'Other (With Alien Number)',
                    'alien_number' => '123456789',
                    'passport_number' => 'Jsdhf73',
                    'sevis_id' => '1234567891',
                    'expiration_date' => '02/29/2020',
                    'country_of_citizenship' => 'Algeria',
                    'description' => 'Some type of document'
                  }
                }
              }
            }
          }
        end

        let(:params) { ActionController::Parameters.new(valid_params)}

        before do
          subject.validate_vlp_params(params, 'dependent', nil, dependent)
        end

        it 'should not add any errors to the object if params are valid' do
          expect(dependent.errors.full_messages).to be_empty
        end
      end
    end
  end
end
