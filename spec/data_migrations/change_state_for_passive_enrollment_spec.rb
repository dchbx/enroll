require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_state_for_passive_enrollment")

describe ChangeStateForPassiveEnrollment, dbclean: :after_each do

  let(:given_task_name) { "deactivate_consumer_role" }

  subject { ChangeStateForPassiveEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing passive enrollment aasm state" do

    let(:start_on)                    { TimeKeeper.date_of_record.beginning_of_month+2.months - 1.year }
    let(:organization)                { FactoryBot.create :organization, legal_name: "Corp 1" }
    let(:employer_profile)            { FactoryBot.create :employer_profile, organization: organization }
    let!(:benefit_group) { FactoryBot.create(:benefit_group)}
    let!(:plan_year) { FactoryBot.create(:plan_year, aasm_state:'terminated', start_on: start_on, benefit_groups:[benefit_group], employer_profile: employer_profile) }

    let!(:renewing_benefit_group) { FactoryBot.create(:benefit_group)}
    let!(:renewing_plan_year) { FactoryBot.create(:plan_year, start_on: start_on.next_year, aasm_state:'renewing_draft', benefit_groups: [renewing_benefit_group], employer_profile: employer_profile) }

    let!(:benefit_group_assignment) { FactoryBot.create(:benefit_group_assignment, benefit_group_id: benefit_group.id, is_active: true, census_employee: census_employee) }
    let!(:renewal_benefit_group_assignment) { FactoryBot.create(:benefit_group_assignment, benefit_group_id: renewing_benefit_group.id, is_active: false, census_employee: census_employee, start_on: renewing_benefit_group.start_on) }

    let(:census_employee)             { FactoryBot.create :census_employee, employer_profile: employer_profile }
    let!(:person)                      { FactoryBot.create(:person, :with_family, :with_ssn) }

    let!(:employee_role)              { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer_profile) }
    let(:family)                            { person.primary_family }
    let!(:enrollment_one)              { FactoryBot.create(:hbx_enrollment,
                                             household: family.active_household,
                                             family:family,
                                             coverage_kind: "dental",
                                             effective_on: renewing_plan_year.start_on.next_month,
                                             enrollment_kind: "open_enrollment",
                                             benefit_group_assignment: renewal_benefit_group_assignment,
                                             kind: "employer_sponsored",
                                             benefit_group: renewing_benefit_group,
                                             submitted_at: TimeKeeper.date_of_record,
                                             aasm_state: 'coverage_selected') }
    let!(:enrollment_two)              { FactoryBot.create(:hbx_enrollment,
                                             household: family.active_household,
                                             family:family,
                                             coverage_kind: "health",
                                             effective_on: renewing_plan_year.start_on.next_month,
                                             enrollment_kind: "open_enrollment",
                                             benefit_group_assignment: renewal_benefit_group_assignment,
                                             benefit_group: renewing_benefit_group,
                                             kind: "employer_sponsored",
                                             submitted_at: TimeKeeper.date_of_record,
                                             aasm_state: 'coverage_canceled') }

    it "should change the passive enrollment aasm state" do
      person.employee_roles =[employee_role]
      person.save
      expect(enrollment_two.aasm_state).to eq "coverage_canceled"
      subject.migrate
      enrollment_two.reload
      expect(enrollment_two.aasm_state).to eq "coverage_enrolled"
    end

    it "should not change the active enrollment aasm state" do
      expect(enrollment_one.aasm_state).to eq "coverage_selected"
      subject.migrate
      enrollment_one.reload
      expect(enrollment_one.aasm_state).to eq "coverage_selected"
    end
  end
end
