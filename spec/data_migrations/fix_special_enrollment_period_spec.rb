require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_special_enrollment_period.rb")

describe FixSpecialEnrollmentPeriod do
  let(:given_task_name) { "fix_special_enrollment_period" }
  subject { FixSpecialEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "fix sep invalid records" do
    let(:date) {TimeKeeper.date_of_record}
    let!(:plan_year) { FactoryGirl.build(:plan_year, aasm_state:'active')}
    let(:employer_profile) { FactoryGirl.create(:employer_profile,plan_years:[plan_year])}
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment)}
    let(:census_employee) { FactoryGirl.create(:census_employee,hired_on:date,benefit_group_assignments:[benefit_group_assignment])}
    let(:employee_role) { FactoryGirl.build(:employee_role,employer_profile:employer_profile,census_employee:census_employee)}
    let!(:person) { FactoryGirl.create(:person, :with_ssn)}
    let!(:add_emp_role) {person.employee_roles = [employee_role]
      person.save
    }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:special_enrollment_period) {FactoryGirl.build(:special_enrollment_period,family:family,optional_effective_on:[Date.strptime(plan_year.start_on.to_s, "%m/%d/%Y").to_s])}
    let!(:add_special_enrollemt_period) {family.special_enrollment_periods = [special_enrollment_period]
                                          family.save
    }

    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      special_enrollment_period.next_poss_effective_date=[plan_year.end_on.next_day.to_s]
      special_enrollment_period.save(validate:false) # adding error next_poss_effective_date.
    end

    it "should fix next_poss_effective_date validation and update with valid plan year" do
      expect(family.special_enrollment_periods.map(&:valid?)).to eq [false]  # before migration
      subject.migrate
      special_enrollment_period.reload
      expect(family.special_enrollment_periods.map(&:valid?)).to eq [true]  # after migration
      expect(special_enrollment_period.next_poss_effective_date).to eq plan_year.end_on

    end
  end
end