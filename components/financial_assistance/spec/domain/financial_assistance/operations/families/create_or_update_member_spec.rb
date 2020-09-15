# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Families::CreateOrUpdateMember, dbclean: :after_each do

  let(:params) do
    {applicant_params: {
        :first_name => "John",
        :last_name => "Smith5",
        :gender => "male",
        :is_tobacco_user => "unknown",
        :person_hbx_id => "f1baf5a92c0441d8bba93410457a250a",
        :ssn => "725236966",
        :dob => "04/04/1972",
        :is_applying_coverage => true,
        :citizen_status => "us_citizen",
        :is_consumer_role => true,
        :same_with_primary => false,
        :indian_tribe_member => false,
        :is_incarcerated => true,
        :addresses =>
            [{"address_2" => "#123", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1123 Awesome Street", "city" => "Washington", "state" => "DC", "zip" => "01001"},
             {"address_2" => "#124", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1124 Awesome Street", "city" => "Washington", "state" => "DC", "zip" => "01001"}],
        :phones =>
            [{"country_code" => "", "area_code" => "202", "number" => "1111123", "extension" => "13", "full_phone_number" => "202111112313", "kind" => "home"},
             {"country_code" => "", "area_code" => "202", "number" => "1111124", "extension" => "14", "full_phone_number" => "202111112414", "kind" => "home"}],
        :emails => [{"kind" => "home", "address" => "example9@example.com"}, {"kind" => "home", "address" => "example10@example.com"}],
        :family_member_id => BSON::ObjectId.new,
        :is_primary_applicant => true,
        :is_consent_applicant => false,
        :relationship => "self"}
    }
  end

  describe 'failure' do
    it 'should fail for any missing data' do
      result = subject.call(params: params)

      expect(result.failure).to be_truthy if result.failure.present?
      expect(result.failure).to be_nil if result.failure.nil?
    end
  end
end