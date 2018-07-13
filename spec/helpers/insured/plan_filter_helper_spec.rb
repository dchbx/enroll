require "rails_helper"
include Config::SiteHelper

RSpec.describe Insured::PlanFilterHelper, :type => :helper do
  context "Shows Find Your Doctor link based on market kind" do
    it "should return link for shop" do
      @market_kind="shop"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"#{find_your_doctor_url}\">Find Your Doctor</a>"
    end

    it "should return link for individual" do
      @market_kind="individual"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/dc/\">Find Your Doctor</a>"
    end
  end

  context ".estimate_your_costs" do
    it "should return link for congressional employee" do
      @market_kind="shop"
      @dc_checkbook_url=Settings.checkbook_services.congress_url
      @coverage_kind="health"
      expect(estimate_your_costs).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/congress/dc/2018/\">Estimate Your Costs</a>"
    end

    it "should return link for non-congressional employee" do
      @market_kind="shop"
      @coverage_kind = "health"
      @dc_checkbook_url="fake_url"
      expect(estimate_your_costs).to eq "<a target=\"_blank\" href=\"fake_url\">Estimate Your Costs</a>"
    end
  end
end
