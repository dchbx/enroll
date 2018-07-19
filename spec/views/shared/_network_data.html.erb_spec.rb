require 'rails_helper'

RSpec.describe "shared/_network_data.html.erb" do

  let(:mock_dc_plan) { double("DCPlan", nationwide: true)}
  let(:mock_ma_plan) { double("MAPlan", network_information: "sample data")}

  context "DC Plan" do

    it "should have nationwide as true" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(true)
      render partial: "shared/network_data", locals: {plan: mock_dc_plan}
      expect(rendered).to have_selector("th", text: "Nationwide")
    end

    it "should have dc metro as true" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(true)
      allow(mock_dc_plan).to receive(:nationwide).and_return(false)
      render partial: "shared/network_data", locals: {plan: mock_dc_plan}
      expect(rendered).to have_selector("th", text: "DC-Metro")
    end
  end

  context "MA plan" do

    it "should have network information" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(false)
      render partial: "shared/network_data", locals: {plan: mock_ma_plan}
      expect(rendered).to match("sample data")
    end

  end

end
