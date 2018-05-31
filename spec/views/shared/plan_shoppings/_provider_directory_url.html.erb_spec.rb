require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_provider_directory_url.html.erb" do

  let(:mock_dc_plan) { double("DCPlan", provider_directory_url: "www.example.com") }
  let(:mock_dc_qhps) { [double("DCQHP", plan: mock_dc_plan)]}
  let(:mock_ma_plan) { double("MAPlan", provider_directory_url: "www.example1.com")}
  let(:mock_ma_qhps) { [double("MAQHP", plan: mock_ma_plan)]}

  context "DC Plan" do

    it "should have provider directory url" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(true)
      allow(mock_dc_plan).to receive(:nationwide).and_return(true)
      render partial: "shared/plan_shoppings/provider_directory_url", locals: {qhps: mock_dc_qhps}
      expect(rendered).to match(/#{mock_dc_plan.provider_directory_url}/)
    end
  end

  context "MA plan" do

    it "should have provider directory url" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(false)
      render partial: "shared/plan_shoppings/provider_directory_url", locals: {qhps: mock_ma_qhps}
      expect(rendered).to match(/#{mock_ma_plan.provider_directory_url}/)
    end

  end
end
