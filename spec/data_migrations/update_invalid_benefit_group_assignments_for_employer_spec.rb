require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_invalid_benefit_group_assignments_for_employer')

describe UpdateInvalidBenefitGroupAssignmentsForEmployer, dbclean: :after_each do

  let(:given_task_name) { 'update_invalid_benefit_group_assignments_for_employer' }
  subject { UpdateInvalidBenefitGroupAssignmentsForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing plan year state"' do

    let!(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
    let(:plan_year) { FactoryBot.create(:plan_year) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group, hbx_enrollment: hbx_enrollment, start_on: TimeKeeper.date_of_record - 5.years)}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}

    before(:each) do
      benefit_group_assignments = [benefit_group_assignment]
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      allow(census_employee).to receive(:benefit_group_assignments).and_return benefit_group_assignments
      allow(benefit_group_assignment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group_assignment).to receive_message_chain(:hbx_enrollment, :benefit_group).and_return(benefit_group)

    end

    context 'updating benefit group assignments', dbclean: :after_each do

      it 'should update the invalid benefit group assignments' do
        ClimateControl.modify fein: plan_year.employer_profile.parent.fein do
          allow(benefit_group_assignment).to receive(:valid?).and_return(false)
          allow(benefit_group_assignment).to receive_message_chain(:hbx_enrollment, :update_attributes!).with(benefit_group_id: benefit_group.id)
          allow(benefit_group_assignment).to receive_message_chain(:hbx_enrollment, :benefit_group_id ).and_return(true)

          subject.migrate
          census_employee.reload
          census_employee.benefit_group_assignments.each do |bga|
            expect(bga.benefit_group.id).to eq(bga.hbx_enrollment.benefit_group.id)
          end
        end
      end
    end
  end
end
