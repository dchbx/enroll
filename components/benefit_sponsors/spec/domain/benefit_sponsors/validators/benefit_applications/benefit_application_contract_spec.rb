# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::BenefitApplications::BenefitApplicationContract do

  let(:effective_date)                 { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:oe_start_on)                    { TimeKeeper.date_of_record.beginning_of_month}
  let(:expiration_date)                { effective_date }
  let(:effective_period)               { effective_date..(effective_date + 1.year).prev_day }
  let(:oe_period)                      { oe_start_on..(oe_start_on + 10.days) }      
  let(:terminated_on)                  { effective_date.end_of_month }       
  let(:termination_kind)               { "non_payment"}
  let(:termination_reason)             { "non_payment_termination_reason"}  
  let(:missing_params)                 { {expiration_date: expiration_date, open_enrollment_period: oe_period, aasm_state: :draft, recorded_rating_area_id: BSON::ObjectId.new, benefit_sponsor_catalog_id: BSON::ObjectId.new } }
  let(:invalid_params)                 { missing_params.merge({recorded_service_area_ids: BSON::ObjectId.new, effective_period: effective_date})}
  let(:error_message1)                 { {:effective_period => ["is missing"], :recorded_service_area_ids => ["is missing"]} }
  let(:error_message2)                 { {:recorded_service_area_ids => ["must be an array"], :effective_period => ["must be Range"]} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({effective_period: effective_period, recorded_service_area_ids: [BSON::ObjectId.new] })}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end

    context "with valid all params" do
      let(:all_params) do
        valid_params.merge({terminated_on: terminated_on, fte_count: 20, pte_count: 10, msp_count: 1, recorded_sic_code: '034',
                            predecessor_id: BSON::ObjectId.new, termination_kind: termination_kind, termination_reason: termination_reason})
      end 

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end