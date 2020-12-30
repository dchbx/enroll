# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Products::PremiumTableContract do

  let(:effective_date)      { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:effective_period)    { effective_date.beginning_of_year..(effective_date.end_of_year) }
  let(:premium_tuples)      { {_id: BSON::ObjectId.new, age: 12, cost: 227.07} }
  let(:rating_area_id)      { BSON::ObjectId.new }

  let(:missing_params)      { {_id: BSON::ObjectId.new, effective_period: effective_period, premium_tuples: [premium_tuples]} }
  let(:invalid_params)      { {_id: BSON::ObjectId.new, premium_tuples: [premium_tuples], effective_period: effective_date, rating_area_id: rating_area_id} }
  let(:error_message1)      { {:rating_area_id => ["is missing"]} }
  let(:error_message2)      { {:effective_period => ["must be Range"]} }

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
    context "with all params" do
      let(:required_params)  { missing_params.merge({rating_area_id: rating_area_id}) }

      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end