# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Application::Create, dbclean: :after_each do
  let(:params) do
    {:family_id => BSON::ObjectId.new,
     :assistance_year => 2020,
     :benchmark_product_id => BSON::ObjectId.new,
     :is_ridp_verified => false,
     :applicants =>
       [{:first_name => "John",
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
          [{"address_2" => "#123", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1123 Awesome Street NE", "city" => "Washington", "state" => "DC", "zip" => "01001"},
           {"address_2" => "#124", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1124 Awesome Street NE", "city" => "Washington", "state" => "DC", "zip" => "01001"}],
         :phones =>
          [{"country_code" => "", "area_code" => "202", "number" => "1111123", "extension" => "13", "full_phone_number" => "202111112313", "kind" => "home"},
           {"country_code" => "", "area_code" => "202", "number" => "1111124", "extension" => "14", "full_phone_number" => "202111112414", "kind" => "home"}],
         :emails => [{"kind" => "home", "address" => "example9@example.com"}, {"kind" => "home", "address" => "example10@example.com"}],
         :family_member_id => BSON::ObjectId.new,
         :is_primary_applicant => true,
         :is_consent_applicant => false,
         :relationship => "self"},
        {:first_name => "John",
         :last_name => "Smith6",
         :gender => "male",
         :is_tobacco_user => "unknown",
         :person_hbx_id => "21a52bd40ec44ea6b49ef284a91b14e2",
         :ssn => nil,
         :dob => "04/04/1972",
         :is_applying_coverage => true,
         :citizen_status => "us_citizen",
         :is_consumer_role => true,
         :same_with_primary => false,
         :indian_tribe_member => false,
         :is_incarcerated => false,
         :addresses =>
          [{"address_2" => "#125", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1125 Awesome Street", "city" => "Washington", "state" => "DC", "zip" => "01001"},
           {"address_2" => "#126", "address_3" => "", "county" => "Hampden", "country_name" => "", "kind" => "home", "address_1" => "1126 Awesome Street", "city" => "Washington", "state" => "DC", "zip" => "01001"}],
         :phones =>
          [{"country_code" => "", "area_code" => "202", "number" => "1111125", "extension" => "15", "full_phone_number" => "202111112515", "kind" => "home"},
           {"country_code" => "", "area_code" => "202", "number" => "1111126", "extension" => "16", "full_phone_number" => "202111112616", "kind" => "home"}],
         :emails => [{"kind" => "home", "address" => "example11@example.com"}, {"kind" => "home", "address" => "example12@example.com"}],
         :family_member_id => BSON::ObjectId.new,
         :is_primary_applicant => false,
         :is_consent_applicant => false,
         :relationship => "child"}]}
  end

  let(:result) { subject.call(params: params) }
  let(:application) { FinancialAssistance::Application.find(result.success) }

  it 'exports payload successfully' do
    expect(result.success?).to be_truthy
  end

  it 'has the right number of applicants' do
    expect(application.applicants.count).to be(2)
  end

  it 'creates relationships with the primary applicant' do
    expect(application.relationships.find_by(relative_id: application.primary_applicant.id).kind).to eql("child")
  end

  it 'exports a payload' do
    expect(result.success).to be_a_kind_of(BSON::ObjectId)
  end
end