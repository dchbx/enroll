# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::Delete, dbclean: :after_each do

  let(:family_id)    { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft") }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      ssn: '889984400',
                      dob: Date.new(1993,12,9),
                      first_name: 'james',
                      last_name: 'bond')
  end

  let(:applicant_params) do
    {:person_hbx_id => applicant.person_hbx_id,
     :ssn => "889984400",
     :dob => "09/12/1993",
     first_name: 'james',
     last_name: 'bond',
     gender: 'male',
     :is_applying_coverage => true,
     :citizen_status => "us_citizen",
     :is_consumer_role => true,
     :same_with_primary => false,
     :indian_tribe_member => false,
     :is_incarcerated => true,
     :addresses => [{"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a4a'),
                     "address_2" => "#111",
                     "address_3" => "",
                     "county" => "Hampden",
                     "country_name" => "",
                     "kind" => "home",
                     "address_1" => "1111 Awesome Street NE",
                     "city" => "Washington",
                     "state" => "DC",
                     "zip" => "01001"}],
     :phones => [
      {"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a4e'),
       "country_code" => "",
       "area_code" => "202",
       "number" => "1111111",
       "extension" => "1",
       "full_phone_number" => "20211111111",
       "kind" => "home"}
],
     :emails => [
      {"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a52'), "kind" => "home", "address" => "example1@example.com"}
],
     :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
     :is_primary_applicant => true,
     :is_consent_applicant => false,
     :relationship => "self"}
  end

  let(:applicant_params_2) do
    {:person_hbx_id => "13cce9fe14b04209b2443330900108d8",
     :ssn => "705335062",
     :dob => "04/04/1972",
     first_name: 'test',
     last_name: 'bond',
     gender: 'male',
     :is_applying_coverage => true,
     :citizen_status => "us_citizen",
     :is_consumer_role => true,
     :same_with_primary => false,
     :indian_tribe_member => false,
     :is_incarcerated => true,
     :addresses => [{"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a4a'),
                     "address_2" => "#111",
                     "address_3" => "",
                     "county" => "Hampden",
                     "country_name" => "",
                     "kind" => "home",
                     "address_1" => "1111 Awesome Street NE",
                     "city" => "Washington",
                     "state" => "DC",
                     "zip" => "01001"}],
     :phones => [
      {"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a4e'),
       "country_code" => "",
       "area_code" => "202",
       "number" => "1111111",
       "extension" => "1",
       "full_phone_number" => "20211111111",
       "kind" => "home"}
],
     :emails => [
      {"_id" => BSON::ObjectId('5f60c648bb40ee0c3d288a52'), "kind" => "home", "address" => "example1@example.com"}
],
     :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
     :is_primary_applicant => true,
     :is_consent_applicant => false,
     :relationship => "self"}
  end

  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      ssn: '889984400',
                      dob: (Date.today - 10.years),
                      first_name: 'test',
                      last_name: 'person1')
  end

  describe 'when a draft application is present with an applicant' do

    it 'should be delete the applicant' do
      expect(application.applicants.count).to eq 1
      subject.call(financial_applicant: applicant_params, family_id: family_id)
      expect(application.reload.applicants.count).to eq 0
    end
  end

  describe "when there is no application" do
    it 'should not delete the applicant' do
      application.update!(aasm_state: "determined")
      result = subject.call(financial_applicant: applicant_params, family_id: family_id)
      expect(result.failure?).to be_truthy
    end
  end

  describe "When there is no applicant" do
    it 'should not delete the applicant' do
      result = subject.call(financial_applicant: applicant_params_2, family_id: family_id)
      expect(result.failure?).to be_truthy
    end
  end
end
