require 'rails_helper'

describe "app/views/events/v2/employers/_elected_plan.xml.haml" do
  let!(:issuer_profile)  { FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:carrier_special_plan_id)  { "abcde" }
  let!(:application_period)  { TimeKeeper.date_of_record.beginning_of_month..TimeKeeper.date_of_record.beginning_of_month + 1.year }
  let!(:elected_plan)  { BenefitMarkets::Products::DentalProducts::DentalProduct.create(application_period: application_period, issuer_assigned_id:carrier_special_plan_id,issuer_profile: issuer_profile) }

  before :each do
    allow(elected_plan).to receive(:ehb).and_return(0.0)
    render :template => "events/v2/employers/_elected_plan.xml.haml", locals: { elected_plan: elected_plan }
  end

  describe "given a plan with a carrier_special_plan_identifier" do

    let(:carrier_special_plan_id) { "abcde" }
    let(:expected_plan_alias_id) { Settings.aca.carrier_special_plan_identifier_namespace + carrier_special_plan_id }

    it "includes the alias  id" do
      expect(rendered).to have_selector("elected_plan id alias_ids alias_id id", :text => expected_plan_alias_id) 
    end
  end
end
