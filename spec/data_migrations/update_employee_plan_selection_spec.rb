require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_employee_plan_selection")

describe UpdateEmployeePlanSelection, dbclean: :after_each do
  let(:given_task_name) { "update_employee_plan_selection" }
  subject { UpdateEmployeePlanSelection.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing employer contributions" do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:family){FactoryGirl.create(:family,:with_primary_family_member)}
    let!(:hbx_enrollment){FactoryGirl.create(:hbx_enrollment, benefit_group:benefit_group,household:family.active_household)}
    let(:plan){FactoryGirl.create(:plan,hios_id:"12345")}
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(benefit_group.employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("hios_id").and_return(plan.hios_id)
      allow(ENV).to receive(:[]).with("active_year").and_return(plan.active_year)

    end
    it "should not change the employee plan if the plan year is not published" do
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.first.plan.hios_id).not_to eq plan.hios_id
    end
    it "should change the employee plan selection" do
      benefit_group.plan_year.update_attributes(aasm_state: "published")
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.first.plan.hios_id).to eq plan.hios_id
    end
  end
end
