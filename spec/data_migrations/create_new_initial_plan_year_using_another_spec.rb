require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_new_initial_plan_year_using_another")

describe CreateNewInitialPlanYearUsingAnother, dbclean: :around_each do
  let(:given_task_name) { "create_new_initial_plan_year_using_another" }
  subject { CreateNewInitialPlanYearUsingAnother.new(given_task_name, double(:current_scope => nil)) }
  let(:benefit_group) { existing_plan_year.benefit_groups.first }
  let(:existing_plan_year) { FactoryGirl.create(:custom_plan_year, employer_profile: employer_profile) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:organization) { employer_profile.organization }
  let(:start_on) { "01012017" }
  let!(:rating_area) { RatingArea.first || FactoryGirl.create(:rating_area)  }

  describe "create_initial_plan_year", dbclean: :after_each do
    it "creates a new plan year" do
      new_plan_year = subject.create_initial_plan_year(organization, existing_plan_year, "01012017")
      expect(employer_profile.plan_years.length).to be 2
      expect(employer_profile.plan_years).to include(new_plan_year)
      expect(new_plan_year.start_on.strftime("%m%d%Y")).to include(start_on)
    end
  end

  describe "force_publish!" do
    context "plan_year.application_errors absent" do
      before do
        plan_year = benefit_group.plan_year
        plan_year.fte_count = 3
        allow(plan_year).to receive(:application_errors).and_return({})
      end
      it "sets the plan year in enrolling state" do
        enrolling_plan_year = subject.force_publish!(benefit_group.plan_year)
        expect(enrolling_plan_year.enrolling?).to be true
      end
    end

    context "plan_year.application_errors present" do
      before do
        benefit_group.plan_year.application_errors[:publish] = "some error"
        benefit_group.save!
      end
      it "sets the plan year in enrolling state" do
        enrolling_plan_year = subject.force_publish!(benefit_group.plan_year)
        expect(enrolling_plan_year.enrolling?).to be true
      end
    end
  end
end
