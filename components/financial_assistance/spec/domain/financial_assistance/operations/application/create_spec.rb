# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Application::Create, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:family) { person.primary_family }

  let(:applicant) do
    {
      first_name: "James", last_name: "Bond", ssn: "101010101", gender: "male", dob: Date.new(1993, 3, 8),
      is_incarcerated: false, indian_tribe_member: false, citizen_status: "US citizen",
      is_consumer_role: true, same_with_primary:  true, is_applying_coverage: true
    }
  end

  let(:required_params) do
    {
      family_id: family.id, assistance_year: 2020, benchmark_product_id: BSON::ObjectId.new,
      years_to_renew: 2021, applicants: [applicant]
    }
  end

  let(:result) { subject.call(params: required_params) }

  it 'exports payload successfully' do
    expect(result.success?).to be_truthy
  end

  it 'exports a payload' do
    binding.pry
    expect(result.success).to be_a_kind_of(FinancialAssistance::Entities::Application)
  end
end