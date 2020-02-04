# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Entities::Validators::BenefitSponsorCatalogContract do

  let(:effective_date)          { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:effective_period)        { effective_date..(effective_date + 1.year) }
  let(:oe_start_on)             { TimeKeeper.date_of_record.beginning_of_month}
  let(:open_enrollment_period)  { oe_start_on..(oe_start_on + 10.days) }
  let(:probation_period_kinds)  { [] }
  let(:benefit_application)     { {} }
  let(:product_packages)        { [{}] }
  let(:service_areas)           { [{}] }

  let(:missing_params)          { {effective_date: effective_date, effective_period: effective_period, open_enrollment_period: open_enrollment_period, service_areas: service_areas} }
  let(:all_params)              { {} }

  let(:error_message) { { :probation_period_kinds => ["is missing"], :benefit_application => ["is missing"], :product_packages => ["is missing"] } }


  context "Given invalid required parameters" do
    # context "sending with missing parameters should fail validation with :errors" do
    #   it { expect(subject.call(missing_params).failure?).to be_truthy }
    #   it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    # end
  end
end