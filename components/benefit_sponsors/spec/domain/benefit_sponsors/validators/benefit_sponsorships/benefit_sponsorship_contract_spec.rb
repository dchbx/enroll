# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::BenefitSponsorships::BenefitSponsorshipContract do

  let(:effective_date)                 { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:oe_start_on)                    { TimeKeeper.date_of_record.beginning_of_month}
  let(:expiration_date)                { effective_date }
  let(:effective_period)               { effective_date..(effective_date + 1.year).prev_day }
  let(:oe_period)                      { oe_start_on..(oe_start_on + 10.days) }      
  let(:terminated_on)                  { effective_date.end_of_month }       
  let(:termination_kind)               { "non_payment"}
  let(:termination_reason)             { "non_payment_termination_reason"}  
  let(:missing_params)                 { {_id: BSON::ObjectId.new, hbx_id: '1234567', aasm_state: :draft, profile_id: BSON::ObjectId.new, source_kind: :self_serve  } }
  let(:invalid_params)                 { missing_params.merge({is_no_ssn_enabled: 1, market_kind: :aca_shop, registered_on: 'today' })}
  let(:error_message1)                 { {:market_kind => ["is missing"], :organization_id => ["is missing"]} }
  let(:error_message2)                 { {:organization_id => ["is missing"], :registered_on => ["must be a date"]} }

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
    let(:valid_params_1) { missing_params.merge({is_no_ssn_enabled: true, market_kind: :aca_shop, organization_id: BSON::ObjectId.new, registered_on: oe_start_on})}
    let(:valid_params_2) { missing_params.merge({is_no_ssn_enabled: true, market_kind: :aca_shop, organization_id: BSON::ObjectId.new, registered_on: nil})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params_1).success?).to be_truthy
        expect(subject.call(valid_params_1).to_h).to eq valid_params_1
      end

      it "should pass validation" do
        expect(subject.call(valid_params_2).success?).to be_truthy
        expect(subject.call(valid_params_2).to_h).to eq valid_params_2
      end
    end

    context "with valid all params" do
      let(:benefit_application) do
        {
          expiration_date: expiration_date, open_enrollment_period: oe_period, aasm_state: :draft, recorded_rating_area_id: BSON::ObjectId.new,
          benefit_sponsor_catalog_id: BSON::ObjectId.new, effective_period: effective_period, recorded_service_area_ids: [BSON::ObjectId.new]
        }   
      end 
      let(:all_params) do
        valid_params_1.merge({benefit_applications: [benefit_application], effective_begin_on: effective_period.min, effective_end_on: effective_period.max,
                            ssn_enabled_on: nil , ssn_disabled_on: nil })
      end 

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end