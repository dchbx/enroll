# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::EnrollmentEligibilityContract do

  let(:market_kind)                { :aca_shop }
  let(:benefit_sponsorship_id)     { BSON::ObjectId.new }
  let(:effective_date)             { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:benefit_application_kind)   { :initial }
  let(:service_area)               { FactoryBot.create(:benefit_markets_locations_service_area) }

  let(:missing_params)             { {market_kind: market_kind, effective_date: effective_date, benefit_sponsorship_id: benefit_sponsorship_id  } }
  let(:invalid_params)             { missing_params.merge({service_areas: service_area.as_json, benefit_application_kind: 'initial' })}
  let(:error_message1)             { {:service_areas => ["is missing"], :benefit_application_kind => ["is missing"]} }
  let(:error_message2)             { {:service_areas => ["must be an array"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    context "with all/required params" do
      let(:all_params) { missing_params.merge({benefit_application_kind: benefit_application_kind, service_areas: [service_area.as_json] }) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end