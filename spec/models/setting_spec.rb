require 'rails_helper'

describe Setting do
  context "individual_market_monthly_enrollment_due_on" do
    it "should get setting_record" do
      expect(Setting.get_individual_market_monthly_enrollment_due_on).to eq Setting.where(name: "individual_market_monthly_enrollment_due_on").last
    end

    it "should get default value from setting_record" do
      expect(Setting.individual_market_monthly_enrollment_due_on).to eq 19
    end
  end
end
