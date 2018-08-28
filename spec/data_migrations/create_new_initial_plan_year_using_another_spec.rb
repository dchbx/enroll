require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_new_initial_plan_year_using_another")

describe CreateNewInitialPlanYearUsingAnother, dbclean: :after_each do
  let(:given_task_name) { "create_new_initial_plan_year_using_another" }
  subject { CreateNewInitialPlanYearUsingAnother.new(given_task_name, double(:current_scope => nil)) }
  let(:benefit_group) { existing_plan_year.benefit_groups.first }
  let(:existing_plan_year) { FactoryGirl.create(:custom_plan_year, employer_profile: employer_profile) }
  let(:existing_future_plan_year) { FactoryGirl.create(:plan_year, start_on:TimeKeeper.date_of_record.beginning_of_month + 2.months, employer_profile: employer_profile) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:organization) { employer_profile.organization }
  let(:start_on) { (TimeKeeper.date_of_record.beginning_of_year + 1.month).strftime("%m%d%Y") }
  let(:future_py_start_on) { (TimeKeeper.date_of_record.beginning_of_month + 1.month).strftime("%m%d%Y") }
  let(:new_future_py) { subject.create_initial_plan_year(organization, existing_plan_year, future_py_start_on) }
  let!(:health_plans) {FactoryGirl.create_list(:plan, 5, metal_level: "platinum", market: "shop", plan_type: "ppo", carrier_profile: benefit_group.reference_plan.carrier_profile, active_year: TimeKeeper.date_of_record.year)}

  describe "create_initial_plan_year" do
    it "creates a new plan year" do
      new_plan_year = subject.create_initial_plan_year(organization, existing_plan_year, start_on)
      expect(employer_profile.plan_years.length).to be 2
      expect(employer_profile.plan_years).to include(new_plan_year)
      expect(new_plan_year.start_on.strftime("%m%d%Y")).to include(start_on)
    end
  end

  describe "force_publish!", dbclean: :after_each do
    context "plan_year.application_errors absent" do
      before do
        allow(new_future_py).to receive(:application_errors).and_return({})
      end
      it "sets the plan year in enrolling state" do
        enrolling_plan_year = subject.force_publish!(new_future_py)
        expect(enrolling_plan_year.enrolling?).to be true
      end
    end

    context "plan_year.application_errors present" do
      before do
        new_future_py.application_errors[:publish] = "some error"
        new_future_py.save!
      end
      it "sets the plan year in enrolling state" do
        enrolling_plan_year = subject.force_publish!(new_future_py)
        expect(enrolling_plan_year.enrolling?).to be true
      end
    end
  end

  describe "when reference plan_option_kind changes in new plan year", dbclean: :after_each do
    context "should update new benefit group" do
      before do
        allow(ENV).to receive(:[]).with("open_enrollment_start_on").and_return ''
        allow(ENV).to receive(:[]).with("open_enrollment_end_on").and_return ''
        allow(ENV).to receive(:[]).with("effective_on_offset").and_return ''
        allow(ENV).to receive(:[]).with("plan_option_kind").and_return 'single_carrier'
      end

      it "should update plan option kind" do
        expect(existing_plan_year.benefit_groups.first.plan_option_kind).to eq "single_plan"
        new_plan_year = subject.create_initial_plan_year(organization, existing_plan_year, future_py_start_on)
        expect(new_plan_year.benefit_groups.first.plan_option_kind).to eq "single_carrier"
      end

      it "should update elected_plan_ids" do
        expect(existing_plan_year.benefit_groups.first.elected_plan_ids.count).to eq 1
        new_plan_year = subject.create_initial_plan_year(organization, existing_plan_year, future_py_start_on)
        expect(new_plan_year.benefit_groups.first.elected_plan_ids.count).to eq 6
      end
    end
  end
end
