require 'rails_helper'

describe "app/views/events/v2/employers/_elected_plan.xml.haml" do
  let(:carrier_profile) do 
    instance_double(
      CarrierProfile,
      {
        hbx_carrier_id: "12345",
        legal_name: "CARRIER LEGAL NAME",
        is_active: true
      }
    )
  end
  let(:elected_plan) do
    instance_double(
      Plan,
      {
        carrier_special_plan_identifier: carrier_special_plan_id,
        hios_id: "HIOS ID",
        name: "PLAN NAME",
        is_dental_only?: false,
        active_year: 2015,
        metal_level: "gold",
        coverage_kind: "health",
        ehb: 0.93,
        carrier_profile: carrier_profile
      }
    )
  end

  let(:carrier_special_plan_id) { nil }

  before :each do
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
