require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "triggering_auto_renewals")

describe TriggeringAutoRenewals do

  let(:given_task_name) { "triggering_auto_renewals" }
  subject { TriggeringAutoRenewals.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deleting existing waived renewal enrollment and creating auto renewing enrollment", dbclean: :after_each do

    let(:organization) { 
      org = FactoryGirl.create :organization, legal_name: "Corp 1" 
      employer_profile = FactoryGirl.create :employer_profile, organization: org, profile_source: "conversion"
      active_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :created_at => Date.new(2015,9,1), :start_on => Date.new(2015,12,1), :end_on => Date.new(2016,11,30),
      :open_enrollment_start_on => Date.new(2015,10,1), :open_enrollment_end_on => Date.new(2015, 11, 10), fte_count: 37
      renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolling, :created_at => Date.new(2016,9,1), :start_on => Date.new(2016,12,1), :end_on => Date.new(2017,11,30),
      :open_enrollment_start_on => Date.new(2016,10,12), :open_enrollment_end_on => Date.new(2016, 11, 13), fte_count: 37
      benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      renewing_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      1.times{|i| FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
      employer_profile.census_employees.each do |ce| 
        ce.add_benefit_group_assignment benefit_group, benefit_group.start_on
        ce.add_renew_benefit_group_assignment(renewing_benefit_group)
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({:employee_role =>  employee_role })
        ce.update_attribute(:ssn, ce.employee_role.person.ssn)
        family = Family.find_or_build_from_employee_role(employee_role)
        renewal_plan = FactoryGirl.create(:plan)
        plan = FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)
        

        enrollment_two = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment_two.update_attributes(:aasm_state => 'renewing_waived', coverage_kind: "health")

        enrollment_two = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.active_benefit_group_assignment,
          benefit_group: benefit_group,
          )
        enrollment_two.update_attributes(:aasm_state => 'coverage_selected', coverage_kind: "health", effective_on: Date.new(2015,12,1), plan_id: plan.id)
        ce.renewal_benefit_group_assignment.benefit_group.elected_plan_ids << enrollment_two.plan.renewal_plan_id
        ce.renewal_benefit_group_assignment.benefit_group.save!
      end

      org
    }

    before(:each) do
      allow(Time).to receive(:now).and_return(Time.parse("2016-10-20 00:00:00"))
      allow(ENV).to receive(:[]).with("py_start_on").and_return(organization.employer_profile.plan_years.where(:aasm_state => "renewing_enrolling").first.start_on)
    end

    context "triggering a new enrollment" do

      it "should trigger a auto-renewing enrollment by deleting the waived one", dbclean: :after_each do
        enrollments = organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.where(aasm_state: "renewing_waived")
        expect(enrollments.size).to eq 1
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.size).to eq 2
        subject.migrate
        organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.reload
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.where(aasm_state: "renewing_waived").size).to eq 0
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.where(aasm_state: "auto_renewing").size).to eq 1
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.size).to eq 2
      end
    end
  end
end
