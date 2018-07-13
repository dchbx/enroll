require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "revert_termination_for_employee")

describe RevertTerminationForEmployee, dbclean: :after_each do

  let(:given_task_name) { "revert_termination_for_employee" }
  subject { RevertTerminationForEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "revering EE termination when EE in employment terminated status", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household, terminate_reason: "by_error")}
    let(:employee_role) { FactoryGirl.create(:employee_role)}
    let(:census_employee) { FactoryGirl.build(:census_employee, :termination_details) }

    before do
      allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("census_employee_id").and_return(census_employee.id)
      allow(ShopNoticesNotifierJob).to receive(:perform_later).and_return(true)
      census_employee.class.skip_callback(:save, :after, :assign_default_benefit_package)
      census_employee.save! # We can only change the census record SSN & DOB when CE is in "eligible" status
      census_employee.aasm_state = "employment_terminated"
      census_employee.employee_role_id = employee_role.id
      census_employee.save!
      subject.migrate
      census_employee.reload
      enrollment.reload
    end

    after do
      census_employee.class.set_callback(:save, :after, :assign_default_benefit_package)
    end

    it "should show the state of census employee as linked" do
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end

    it "should unset coverage_terminated_on on census_employee" do
      expect(census_employee.employment_terminated_on).to eq nil
    end

    it "should move enrollment status to enrolled" do
      expect(enrollment.aasm_state).to eq "coverage_enrolled"
    end

    it "should unset terminated_on on enrollment" do
      expect(enrollment.terminated_on).to eq nil
    end

    it "should unset terminate_reason on enrollment" do
      expect(enrollment.terminate_reason).to eq nil
    end
  end
  describe "revering EE termination when EE in employee_termination_pending ", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household, terminate_reason: "by_error")}
    let(:employee_role) { FactoryGirl.create(:employee_role)}
    let(:census_employee) { FactoryGirl.build(:census_employee, :termination_details) }

    before do
      allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("census_employee_id").and_return(census_employee.id)
      census_employee.class.skip_callback(:save, :after, :assign_default_benefit_package)
      census_employee.save! # We can only change the census record SSN & DOB when CE is in "eligible" status
      census_employee.aasm_state = "employee_termination_pending"
      census_employee.employee_role_id = employee_role.id
      census_employee.save!
      subject.migrate
      census_employee.reload
      enrollment.reload
    end

    after do
      census_employee.class.set_callback(:save, :after, :assign_default_benefit_package)
    end

    it "should show the state of census employee as linked" do
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end

    it "should unset employment_terminated_on on census_employee" do
      expect(census_employee.employment_terminated_on).to eq nil
    end

    it "should move enrollment status to enrolled" do
      expect(enrollment.aasm_state).to eq "coverage_enrolled"
    end

    it "should unset terminated_on on enrollment" do
      expect(enrollment.terminated_on).to eq nil
    end

    it "should unset terminate_reason on enrollment" do
      expect(enrollment.terminate_reason).to eq nil
    end
  end
end
