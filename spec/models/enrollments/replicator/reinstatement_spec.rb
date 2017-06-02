require 'rails_helper'

RSpec.describe Enrollments::Replicator::Reinstatement, :type => :model do
  let(:current_date) { Date.new(TimeKeeper.date_of_record.year, 6, 1) }
  let(:effective_on_date)         { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
  let(:terminated_on_date)        {effective_on_date + 10.days}

  let!(:employer_profile) { create(:employer_with_planyear, plan_year_state: 'active', start_on: effective_on_date)}
  let(:benefit_group) { employer_profile.published_plan_year.benefit_groups.first}

  let!(:census_employees){
    FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  }

  let!(:plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: benefit_group.start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let(:ce) { employer_profile.census_employees.non_business_owner.first }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }

  let(:covered_individuals) { family.family_members }
  let(:person) { family.primary_applicant.person }

  let!(:enrollment) {
    FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
     enrollment_members: covered_individuals,
     household: family.active_household,
     coverage_kind: "health",
     effective_on: effective_on_date,
     enrollment_kind: "open_enrollment",
     kind: "employer_sponsored",
     benefit_group_id: benefit_group.id,
     employee_role_id: person.active_employee_roles.first.id,
     benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
     plan_id: plan.id
     )
  }

  before do
    TimeKeeper.set_date_of_record_unprotected!(current_date)
    ce.terminate_employment(effective_on_date + 45.days)
    enrollment.reload
    ce.reload
  end

  context 'when enrollment reinstated' do

    let(:reinstated_enrollment) {
      Enrollments::Replicator::EmployerSponsored.new(enrollment, enrollment.terminated_on.next_day).build
    }

    it "should build reinstated enrollment" do
      expect(reinstated_enrollment.kind).to eq enrollment.kind
      expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
      expect(reinstated_enrollment.plan_id).to eq enrollment.plan_id
    end

    it 'should build a continuous coverage' do
      expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
    end

    it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
      enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
      expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
      expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
      expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
    end   
  end
end
