require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "extending_open_enrollment_end_date_for_employers")

describe ExtendingOpenEnrollmentEndDateForEmployers do

  let(:given_task_name) { "extending_open_enrollment_end_date_for_employers" }
  subject { ExtendingOpenEnrollmentEndDateForEmployers.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the open_enrollment_end_on date for conversion ER's" do

    context "for renewal employer" do
      let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}

      before(:each) do
        organization.employer_profile.renewing_plan_year.update_attribute(:open_enrollment_end_on, Date.new(2016,11,13))
        allow(ENV).to receive(:[]).with("py_start_on").and_return(organization.employer_profile.renewing_plan_year.start_on)
        allow(ENV).to receive(:[]).with("new_oe_end_date").and_return(organization.employer_profile.renewing_plan_year.open_enrollment_end_on + 2.days)
      end

      it "should change the open_enrollment_end_on date of conversion ER" do
        organization.employer_profile.update_attribute(:profile_source, "conversion")
        end_date = organization.employer_profile.renewing_plan_year.open_enrollment_end_on
        subject.migrate
        organization.employer_profile.reload
        expect(organization.employer_profile.renewing_plan_year.open_enrollment_end_on).to eq  (end_date + 2.days)
      end

      it "should change the open_enrollment_end_on date if it renewing non-conversion ER" do
        organization.employer_profile.update_attribute(:profile_source, "self_serve")
        end_date = organization.employer_profile.renewing_plan_year.open_enrollment_end_on
        subject.migrate
        organization.employer_profile.reload
        expect(organization.employer_profile.renewing_plan_year.open_enrollment_end_on).to eq  (end_date + 2.days)
      end
    end

    context "for initial employer" do
      let(:organization) { FactoryGirl.create(:organization, employer_profile: employer_profile)}
      let(:employer_profile) { FactoryGirl.create(:employer_profile)}
      let!(:plan_year) { FactoryGirl.create(:plan_year, aasm_state: "active", employer_profile: employer_profile)}

      before(:each) do
        allow(ENV).to receive(:[]).with("py_start_on").and_return(organization.employer_profile.plan_years.first.start_on)
        allow(ENV).to receive(:[]).with("new_oe_end_date").and_return(organization.employer_profile.plan_years.first.open_enrollment_end_on + 2.days)
      end

      it "should not change the open_enrollment_end_on date for inital employer" do
        end_date = organization.employer_profile.plan_years.first.open_enrollment_end_on
        subject.migrate
        organization.employer_profile.reload
        expect(organization.employer_profile.plan_years.first.open_enrollment_end_on).to eq (end_date)
      end
    end
  end
end
