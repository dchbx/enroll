require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "group_conversion_employers_migration")

describe GroupConversionEmployersMigration, dbclean: :after_each do

  let(:given_task_name) { "group_conversion_employers_migration" }
  subject { GroupConversionEmployersMigration.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state", dbclean: :after_each do

    let(:organization) { FactoryGirl.create :organization, :with_expired_and_active_plan_years, legal_name: "Corp 1", fein: "520818450" }
    let (:census_employee) { FactoryGirl.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years, first_name: person.first_name, last_name: person.last_name }
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: organization.employer_profile)}
    let(:person) { FactoryGirl.create(:person)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, effective_on: Date.new(2016,10,1))}
    before do
      organization.employer_profile.update_attributes(profile_source: "conversion", aasm_state: "eligible")
      census_employee.update_attributes(:employee_role =>  employee_role, :employee_role_id =>  employee_role.id)
      hbx_enrollment.update_attribute(:benefit_group_id, organization.employer_profile.plan_years.where(aasm_state: "active").first.benefit_groups.first.id)
    end

    context "giving a new state", dbclean: :after_each do
      it "should revert the application" do
        expect(organization.employer_profile.aasm_state).to eq "eligible"
        subject.migrate
        organization.reload
        expect(organization.employer_profile.aasm_state).to eq "applicant"
      end

      it "should migrate the 2015 plan year" do
        expired_plan_year = organization.employer_profile.plan_years.where(:aasm_state => "expired").first
        subject.migrate
        expired_plan_year.reload
        expect(expired_plan_year.aasm_state).to eq "migration_expired"
      end

      it "should cancel the 2016 plan year" do
        active_plan_year = organization.employer_profile.plan_years.where(:aasm_state => "active").first
        subject.migrate
        active_plan_year.reload
        expect(active_plan_year.aasm_state).to eq "canceled"
      end

      it "should cancel the enrollments" do
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.first.aasm_state).to eq "coverage_selected"
        subject.migrate
        organization.reload
        expect(organization.employer_profile.census_employees.first.employee_role.person.primary_family.active_household.hbx_enrollments.first.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
