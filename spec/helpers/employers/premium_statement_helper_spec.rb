require "rails_helper"

RSpec.describe Employers::PremiumStatementHelper, :type => :helper do

  describe "#billing_period_options" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}
    before do
      assign(:employer_profile, employer_profile)
    end
    context "when ER has intial plan year which is 4 months old & without renewal plan year" do
      let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
      before do
        start_on = (TimeKeeper.date_of_record).beginning_of_month - 4.months
        plan_year.update_attributes(
        start_on: start_on,
        end_on: start_on + 1.year - 1.day,
        open_enrollment_start_on: (start_on - 30).beginning_of_month,
        open_enrollment_end_on: (start_on - 30).beginning_of_month + 1.weeks,
        aasm_state: "active"
        )
      end
      it "should have  next month in the drop down" do
        expect(helper.billing_period_options.first[1]).to eq TimeKeeper.date_of_record.next_month.beginning_of_month
      end
    end

    context "when ER has plan year which stars 2 months ahead in future" do
      let!(:plan_year) { FactoryGirl.create(:future_plan_year, employer_profile: employer_profile)}
      it "should have plan year start on month in the dropdown" do
        expect(helper.billing_period_options.first[1]).to eq employer_profile.plan_years.first.start_on
      end
    end

    context "when ER has both active & renewal plan years" do
      let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years, employer_profile: employer_profile)}
      before do
        assign(:employer_profile, organization.employer_profile)
      end
      it "should have renewing plan start on date in the dropdown" do
        expect(helper.billing_period_options.first[1]).to eq organization.employer_profile.renewing_plan_year.start_on
      end
    end
  end
end
