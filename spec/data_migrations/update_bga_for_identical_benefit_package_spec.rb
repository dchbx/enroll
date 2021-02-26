# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_bga_for_identical_benefit_package")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe UpdateBgaForIdenticalBenefitPackage, dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:given_task_name) { "update_bga_for_identical_benefit_package" }
  subject { UpdateBgaForIdenticalBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update benefit group assignment for identical benefit package" do

    let!(:census_employee) { FactoryBot.create(:census_employee, dob: TimeKeeper.date_of_record - 21.year, employer_profile_id: nil, benefit_sponsors_employer_profile_id: abc_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment], employee_role_id: employee_role.id) }
    let(:employee_role) { FactoryBot.build(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id: nil, benefit_package: current_benefit_package)}
    let!(:person) {FactoryBot.create(:person,dob: TimeKeeper.date_of_record - 21.year, ssn:census_employee.ssn)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
    let(:active_household) {family.active_household}
    let(:sponsored_benefit) {current_benefit_package.sponsored_benefits.first}
    let!(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, coverage_start_on: current_benefit_package.start_on, eligibility_date: current_benefit_package.start_on, applicant_id: family.family_members.first.id) }
    let!(:enrollment) { FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member], family: family, sponsored_benefit_package_id: current_benefit_package.id, effective_on: initial_application.effective_period.min, household: family.active_household, benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id: employee_role.id, benefit_sponsorship_id: benefit_sponsorship.id)}
    let!(:second_benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: initial_application, title: "old benefit package") }

    before(:each) do
      census_employee.benefit_group_assignments.build(benefit_group: second_benefit_package, start_on: second_benefit_package.start_on, hbx_enrollment_id: enrollment.id)
      census_employee.save(:validate => false)
    end

    it "should update benefit group assignment" do
      ClimateControl.modify fein: abc_organization.fein, title: "first benefit package" do
        expect(census_employee.valid?).to eq false
        expect(census_employee.benefit_group_assignments.last.valid?).to eq false
        subject.migrate
        census_employee.reload
        expect(census_employee.valid?).to eq true
        expect(census_employee.benefit_group_assignments.last.valid?).to eq true
      end
    end
  end
end
