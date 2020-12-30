# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::EnrollmentEligibility::Create, dbclean: :after_each do

  describe 'create enrollment eligibility' do

    let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:market_kind)               { :aca_shop }
    let(:benefit_sponsorship_id)    { BSON::ObjectId.new }
    let(:benefit_application_kind)  { :initial }
    let(:service_area)              { FactoryBot.create(:benefit_markets_locations_service_area) }

    let(:params) do
      {enrollment_eligibility_params: {
        effective_date: effective_date, market_kind: market_kind, benefit_sponsorship_id: benefit_sponsorship_id,
        benefit_application_kind: benefit_application_kind, service_areas: [service_area.as_json]}
     }
    end

    let(:result) { subject.call(params) }

    it 'should be success' do
      expect(result.success?).to be_truthy
    end

    it 'should create EnrollmentEligibility object' do
      expect(result.success).to be_a ::BenefitSponsors::Entities::EnrollmentEligibility
    end
  end
end
