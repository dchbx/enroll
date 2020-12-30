# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Application::RelationshipHandler, dbclean: :after_each do
  let(:family_id) {BSON::ObjectId.new}
  let!(:application) {FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft')}
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      :with_work_phone,
                      :with_work_email,
                      :with_home_address,
                      application: application,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'james',
                      last_name: 'bond',
                      :gender => "male",
                      :is_applying_coverage => true,
                      :citizen_status => "us_citizen",
                      :is_consumer_role => true,
                      :same_with_primary => false,
                      :indian_tribe_member => false,
                      :is_incarcerated => true,
                      :is_primary_applicant => true,
                      :is_consent_applicant => false,
                      :is_disabled => false,
                      :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'))
  end

  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      :with_work_phone,
                      :with_work_email,
                      :with_home_address,
                      application: application,
                      :gender => "male",
                      ssn: '889984401',
                      dob: (Date.today - 10.years),
                      first_name: 'child1',
                      last_name: 'bond',
                      :is_applying_coverage => true,
                      :citizen_status => "us_citizen",
                      :is_consumer_role => true,
                      :same_with_primary => false,
                      :indian_tribe_member => false,
                      :is_incarcerated => true,
                      :is_primary_applicant => false,
                      :is_consent_applicant => false,
                      :is_disabled => false,
                      :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a84'))
  end

  context 'success' do

    before do
      FinancialAssistance::Relationship.skip_callback(:create, :after, :propagate_applicant)
      application.ensure_relationship_with_primary(applicant2, "spouse")
      FinancialAssistance::Relationship.set_callback(:create, :after, :propagate_applicant)
      @result = FinancialAssistance::Operations::Application::RelationshipHandler.new.call({relationship: application.relationships[1]})
    end

    describe 'When applicant_id is primary applicant' do

      it 'should return a success object' do
        expect(@result).to be_a(Dry::Monads::Result::Success)
      end
    end
  end

  context 'failure' do
    before do
      FinancialAssistance::Relationship.skip_callback(:create, :after, :propagate_applicant)
      relationship = application.relationships.create(kind: 'child', applicant_id: applicant2.id, relative_id: applicant.id)
      FinancialAssistance::Relationship.set_callback(:create, :after, :propagate_applicant)
      @result = FinancialAssistance::Operations::Application::RelationshipHandler.new.call({relationship: relationship})
    end

    describe 'When applicant_id is not primary applicant' do

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return a failed message' do
        expect(@result.failure).to eq 'Do not notify enroll app'
      end
    end
  end
end