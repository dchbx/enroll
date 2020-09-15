# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::CreateOrUpdate, dbclean: :after_each do

  let(:family_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'james',
                      last_name: 'bond')
  end

  let(:applicant_params) do
    {:person_hbx_id=>"13cce9fe14b04209b2443330900108d8",
     :ssn=>"705335062",
     :dob=>"04/04/1972",
     first_name: 'test',
     last_name: 'bond',
     gender: 'male',
     :is_applying_coverage=>true,
     :citizen_status=>"us_citizen",
     :is_consumer_role=>true,
     :same_with_primary=>false,
     :indian_tribe_member=>false,
     :is_incarcerated=>true,
     :addresses => [{"_id"=>BSON::ObjectId('5f60c648bb40ee0c3d288a4a'),
      "address_2"=>"#111",
      "address_3"=>"",
      "county"=>"Hampden",
      "country_name"=>"",
      "kind"=>"home",
      "address_1"=>"1111 Awesome Street",
      "city"=>"Washington",
      "state"=>"DC",
      "zip"=>"01001"}],
    :phones=>[
      {"_id"=>BSON::ObjectId('5f60c648bb40ee0c3d288a4e'),
       "country_code"=>"",
       "area_code"=>"202",
       "number"=>"1111111",
       "extension"=>"1",
       "full_phone_number"=>"20211111111",
       "kind"=>"home"}],
    :emails=>[
      {"_id"=>BSON::ObjectId('5f60c648bb40ee0c3d288a52'), "kind"=>"home", "address"=>"example1@example.com"}],
    :family_member_id=>BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
    :is_primary_applicant=>true,
    :is_consent_applicant=>false,
    :relationship=>"self"}
  end

  describe 'when a draft application is present' do
    before do
      @result = subject.call(params: applicant_params, family_id: family_id)
    end

    it 'should return a success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return applicant object' do
      expect(@result.success).to be_a(::FinancialAssistance::Applicant)
    end

    it 'should create a applicant object' do
      expect(application.reload.applicants.count).to eq(2)
    end
  end

  describe 'when a draft application does not exist' do
    before do
      application.update_attributes!(aasm_state: 'submitted')
      @result = subject.call(params: applicant_params, family_id: family_id)
    end

    it 'should return a failure object' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return failure message' do
      expect(@result.failure).to eq('Application Not Found')
    end
  end

  describe 'invalid params' do
    before do
      @result = subject.call(params: {test: 'test'}, family_id: family_id)
    end

    it 'should return a failure object' do
      expect(@result).to be_a(Dry::Monads::Result::Failure)
    end

    it 'should return errors for failed applicant contract validation' do
      expect(@result.failure.errors.present?).to be_truthy
    end
  end
end
