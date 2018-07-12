require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "import_2019_ivl_benefit_package")

describe Import2019IvlBenefitPackage, :dbclean => :after_each do
  let(:given_task_name) { "import_2019_ivl_benefit_package" }
  subject { Import2019IvlBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "create 2019 benefit package for IVL market" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let!(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
    let!(:bcp) { FactoryGirl.create(:benefit_coverage_period, start_on: Date.new(2018,1,1), end_on: Date.new(2018,12,31), open_enrollment_start_on: Date.new(2017,11,1), open_enrollment_end_on: Date.new(2018,1,31), title: "Individual Market Benefits 2018", benefit_sponsorship: benefit_sponsorship) }

    before(:each) do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      subject.migrate
      hbx_profile.reload
    end

    it "should return coverage start on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2019 }
      expect(bcp_2019.start_on).to eq Date.new(2019,1,1)
    end

    it "should return coverage end on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2019 }
      expect(bcp_2019.end_on).to eq Date.new(2019,12,31)
    end

    it "should return open enrollment start on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2019 }
      expect(bcp_2019.open_enrollment_start_on).to eq Date.new(2018,11,1)
    end

    it "should return open enrollment end on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2019 }
      expect(bcp_2019.open_enrollment_end_on).to eq Date.new(2019,1,31)
    end
  end
end
end
