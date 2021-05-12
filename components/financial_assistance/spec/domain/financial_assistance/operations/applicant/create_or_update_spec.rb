# frozen_string_literal: true

require 'rails_helper'
RSpec.describe FinancialAssistance::Operations::Applicant::CreateOrUpdate, dbclean: :after_each do
  let(:family_id) { BSON::ObjectId.new }

  describe 'when a draft application is present' do
    context "and the incoming payload and existing attributes are different" do
      let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
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
                          is_primary_applicant: true)
      end

      let(:applicant_params) do
        {:person_hbx_id => "13cce9fe14b04209b2443330900108d8",
         :ssn => "889984401",
         :dob => (Date.today - 1.years).strftime("%d/%m/%Y"),
         first_name: "childfirst",
         last_name: "childlast",
         gender: "male",
         :is_applying_coverage => true,
         :citizen_status => "us_citizen",
         :is_consumer_role => true,
         :same_with_primary => false,
         :indian_tribe_member => false,
         :is_incarcerated => true,
         :addresses => [{"address_2" => "#111",
                         "address_3" => "",
                         "county" => "Hampden",
                         "country_name" => "",
                         "kind" => "home",
                         "address_1" => "1111 Awesome Street",
                         "city" => "Washington",
                         "state" => "DC",
                         "zip" => "01001"}],
         :phones => [
             {"country_code" => "",
              "area_code" => "202",
              "number" => "1111111",
              "extension" => "1",
              "full_phone_number" => "20211111111",
              "kind" => "home"}
],
         :emails => [{"kind" => "home", "address" => "example1@example.com"}],
         :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
         :is_primary_applicant => true,
         :is_consent_applicant => false,
         :relationship => "child"}
      end

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

    context "and the incoming payload and existing attributes are same" do
      let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
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
                          :is_applying_coverage => true,
                          :citizen_status => "us_citizen",
                          :is_consumer_role => true,
                          :same_with_primary => false,
                          :indian_tribe_member => false,
                          :is_incarcerated => true,
                          :is_primary_applicant => true,
                          :is_consent_applicant => false,
                          :is_disabled => false,
                          :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
                          :relationship => "child")
      end

      let!(:applicant_params) {applicant.serializable_hash.deep_symbolize_keys.merge(:ssn => '889984400', :relationship => "self")}

      before do
        @result = subject.call(params: compare(applicant_params), family_id: family_id)
      end

      it 'should return a failure object' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with message' do
        expect(@result.failure).to eq("No information is changed")
      end

      it 'should create a applicant object' do
        expect(application.reload.applicants.count).to eq(1)
      end
    end

    context "and the incoming payload and existing attributes are same but attributes order changed" do

      let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
      let!(:applicant) do
        appl = FactoryBot.create(:financial_assistance_applicant,
                                 application: application,
                                 ssn: '889984400',
                                 dob: (Date.today - 10.years),
                                 first_name: 'james',
                                 last_name: 'bond',
                                 :is_applying_coverage => true,
                                 :citizen_status => "us_citizen",
                                 :is_consumer_role => true,
                                 :same_with_primary => false,
                                 :indian_tribe_member => false,
                                 :is_incarcerated => true,
                                 :is_primary_applicant => true,
                                 :is_consent_applicant => false,
                                 :is_disabled => false,
                                 :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
                                 :relationship => "child")
        appl.addresses = [FactoryBot.build(:financial_assistance_address, :address_1 => '1111 Awesome Street NE', :address_2 => '#111', :address_3 => '', :city => 'Washington', :country_name => '', :kind => 'work', :state => 'DC', :zip => '20001',
                                                                          county: '')]
        appl.addresses << FactoryBot.build(:financial_assistance_address, :address_1 => '1112 Awesome Street NE', :address_2 => '#112', :address_3 => '', :city => 'Washington', :country_name => '', :kind => 'home', :state => 'DC', :zip => '20001',
                                                                          county: '')
        appl.phones = [FactoryBot.build(:financial_assistance_phone, :area_code => '202', :country_code => '', :extension => '1', :full_phone_number => '20211111111', :kind => 'work', :number => '1111111', :primary => nil)]
        appl.emails = [FactoryBot.build(:financial_assistance_email, :address => 'example1@example.com', :kind => 'work')]
        appl.save!
        appl
      end

      let!(:applicant_params) do
        {:addresses => [{:address_1 => '1112 Awesome Street NE', :address_2 => '#112', :address_3 => '', :city => 'Washington', :country_name => '', :kind => 'home', :quadrant => "", :state => 'DC', :zip => '20001', county: ''},
                        {:address_1 => '1111 Awesome Street NE', :address_2 => '#111', :address_3 => '', :city => 'Washington', :country_name => '', :kind => 'work', :quadrant => "", :state => 'DC', :zip => '20001', county: ''}],
         :alien_number => nil,
         :card_number => nil,
         :citizen_status => "us_citizen",
         :citizenship_number => nil,
         :country_of_citizenship => nil,
         :dob => (Date.today - 10.years).strftime("%d/%m/%Y"),
         :emails => [{:address => "example1@example.com", :kind => "work"}],
         :encrypted_ssn => "wFDFw1whehQ1Udku1/79DA==\n",
         :ethnicity => nil,
         :expiration_date => nil,
         :family_member_id => BSON::ObjectId('5f60c648bb40ee0c3d288a83'),
         :first_name => "james",
         :gender => nil,
         :i94_number => nil,
         :indian_tribe_member => false,
         :is_active => true,
         :is_applying_coverage => true,
         :is_consent_applicant => false,
         :is_consumer_role => true,
         :is_incarcerated => true,
         :is_primary_applicant => true,
         :is_ssn_applied => nil,
         :is_tobacco_user => "unknown",
         :issuing_country => nil,
         :last_name => "bond",
         :middle_name => nil,
         :name_pfx => nil,
         :name_sfx => nil,
         :naturalization_number => nil,
         :no_ssn => "0",
         :passport_number => nil,
         :person_hbx_id => applicant.person_hbx_id,
         :phones => [{:area_code => "202", :country_code => "", :extension => "1", :full_phone_number => "20211111111", :kind => "work", :number => "1111111", :primary => nil}],
         :race => nil,
         :receipt_number => nil,
         :same_with_primary => false,
         :sevis_id => nil,
         :tribal_id => nil,
         :visa_number => nil,
         :vlp_document_id => nil,
         :vlp_subject => nil,
         :vlp_description => nil,
         :relationship => "self",
         :ssn => "889984400"}
      end

      before :each do
        @result = subject.call(params: compare(applicant_params), family_id: family_id)
      end

      it 'should return a failure object' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with a message' do
        expect(@result.failure).to eq('No information is changed')
      end

      it 'should not create a applicant object' do
        expect(application.reload.applicants.count).to eq(1)
      end
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

def compare(applicant_db_hash)
  sanitized_applicant_hash = applicant_db_hash.inject({}) do |db_hash, element_hash|
    db_hash[element_hash[0]] = if [:addresses, :emails, :phones].include?(element_hash[0])
                                 fetch_array_of_attrs_for_embeded_objects(element_hash[1])
                               else
                                 element_hash[1]
                               end
    db_hash
  end
end

def fetch_array_of_attrs_for_embeded_objects(data)
  new_arr = []
  data.each do |special_hash|
    new_arr << special_hash.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary)
  end
  new_arr
end
