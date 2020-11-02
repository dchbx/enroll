# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicant::Build, dbclean: :after_each do
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

  describe 'when valid applicant params passed' do

    let(:result) { subject.call(params: params) }

    it 'should be success' do
      expect(result.success?).to be_truthy
    end

    it 'should build applicant entity object' do
      expect(result.success).to be_a ::FinancialAssistance::Entities::Applicant
    end
  end


  describe 'when invalid applicant params passed' do
    let(:addresses) { [] }
    let(:emails) { [] }

    let(:result) { subject.call(params: params.except(:is_incarcerated)) }

    it 'should be failure' do
      expect(result.failure?).to be_truthy
    end

    it 'should return failure with error messages' do
      expect(result.failure.errors.to_h).to eq(:is_applying_coverage=>['Incarceration question must be answered'])
    end
  end

end
