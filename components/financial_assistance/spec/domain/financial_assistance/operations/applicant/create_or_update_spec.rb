# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::CreateOrUpdate, dbclean: :after_each do
  let(:application) { FactoryBot.create(:application) }
  let(:params) do
    {
      :first_name => "sara",
      :last_name => "test",
      :ssn => "889984400",
      :gender => "female",
      :dob => Date.today - 10.years,
      :is_incarcerated => false,
      :ethnicity => [],
      :indian_tribe_member => true,
      :tribal_id => "777230844",
      :citizen_status => "naturalized_citizen",
      :is_consumer_role => true,
      :same_with_primary => true,
      :is_applying_coverage => true,
      :addresses => addresses,
      :phones => phones,
      :emails => emails
    }
  end
  let(:addresses) { [{"kind" => "home", "address_1" => "55 X Road", "address_2" => "", "city" => "Washington", "state" => "DC", "zip" => "20002"}] }
  let(:phones) { [{"kind" => "home", "full_phone_number" => "(980) 033-3442", "_destroy" => "false"}] }
  let(:emails) { [{"kind" => "home", "address" => "sara@yahoo.com", "_destroy" => "false"}] }

  let(:result) { subject.call(params: params, application: application) }

  describe "with an existing applicant" do
    let(:applicant) { FactoryBot.create :applicant, application: application, ssn: params[:ssn], dob: params[:dob] }

    it "matches the existing applicant" do
      expect(result.success.id).to eql(applicant.id)
    end
  end
end