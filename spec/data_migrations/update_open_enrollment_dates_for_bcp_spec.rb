require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_open_enrollment_dates_for_bcp")

describe UpdateOpenEnrollmentDatesForBcp, dbclean: :after_each do

  let(:given_task_name) { "update_open_enrollment_dates_for_bcp" }
  subject { UpdateOpenEnrollmentDatesForBcp.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update open enrollment dates for benefit coverage period" do
    let!(:organization) { FactoryGirl.create(:organization) }
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period, :organization => organization) }
    let!(:benefit_sponsorship) { hbx_profile.benefit_sponsorship }
    let!(:benefit_coverage_period) { FactoryGirl.create(:benefit_coverage_period, :open_enrollment_coverage_period, benefit_sponsorship: benefit_sponsorship) }
    let(:open_enrollment_start_on) { Date.new(TimeKeeper.date_of_record.year,11,1) }
    let(:open_enrollment_end_on) { Date.new(TimeKeeper.date_of_record.year,12,31) }

    before(:each) do
      allow(ENV).to receive(:[]).with("title").and_return(benefit_coverage_period.title)
      allow(ENV).to receive(:[]).with("new_oe_start_date").and_return(open_enrollment_start_on)
      allow(ENV).to receive(:[]).with("new_oe_end_date").and_return(open_enrollment_end_on)
    end

    context "to update open enrollment dates" do

      it "should update open enrollment start_on and end_on dates" do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        subject.migrate
        expect(benefit_coverage_period.reload.open_enrollment_start_on).to eq open_enrollment_start_on
        expect(benefit_coverage_period.reload.open_enrollment_end_on).to eq open_enrollment_end_on
      end
    end
  end
end
