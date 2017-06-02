require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_new_hire_rule")

describe ChangeNewHireRule do

  let(:given_task_name) { "change_new_hire_rule" }
  subject { ChangeNewHireRule.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing new hire rule" do

    context " changing effective on kind" do
      let(:organization) { FactoryGirl.create(:organization)}
      let(:benefit_group)     { FactoryGirl.build(:benefit_group, effective_on_kind: "date_of_hire")}
      let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group]) }
      let!(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization, plan_years: [plan_year]) }

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return organization.fein
        allow(ENV).to receive(:[]).with("plan_year_state").and_return plan_year.aasm_state
      end

      it "will change the effective on kind for the benefit group from date_of_hire to first_of_month" do
        subject.migrate
        benefit_group.reload
        expect(benefit_group.effective_on_kind).to eq "first_of_month"
      end
    end
  end

end
