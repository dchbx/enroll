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
    let(:benefit_group) { FactoryBot.create(:benefit_group)}
    let(:family){FactoryBot.create(:family,:with_primary_family_member)}
    let!(:hbx_enrollment){FactoryBot.create(:hbx_enrollment, family: family, benefit_group:benefit_group,household:family.active_household)}
    let(:plan){FactoryBot.create(:plan,hios_id:"12345")}

    it "should not change the employee plan if the plan year is not published" do
      ClimateControl.modify fein:benefit_group.employer_profile.parent.fein,hios_id:plan.hios_id,active_year:"#{plan.active_year}" do 
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.first.plan.hios_id).not_to eq plan.hios_id
      end
    end
    it "should change the employee plan selection" do
      ClimateControl.modify fein: benefit_group.employer_profile.parent.fein,hios_id: plan.hios_id,active_year:"#{plan.active_year}" do 
        benefit_group.plan_year.update_attributes(aasm_state: "published")
        subject.migrate
        family.reload
        expect(family.active_household.hbx_enrollments.first.plan.hios_id).to eq plan.hios_id
      end
    end
  end
end
