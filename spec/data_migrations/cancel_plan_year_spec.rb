require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'cancel_plan_year')

describe CancelPlanYear do

  let(:given_task_name) { 'cancel_plan_year' }
  subject { CancelPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'cancel plan year', dbclean: :after_each do
    let(:benefit_group) { FactoryBot.create(:benefit_group)}
    let(:plan_year) { FactoryBot.create(:plan_year, benefit_groups: [benefit_group], aasm_state: 'enrolled')}
    let!(:plan_year2) { FactoryBot.create(:plan_year, aasm_state: 'active')}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: 'coverage_enrolled', benefit_group_id: plan_year.benefit_groups.first.id)}
    let!(:py_params) {{plan_year_state: plan_year.aasm_state, plan_year_start_on: plan_year.start_on.to_s, feins: plan_year.employer_profile.parent.fein}}

    before(:each) do
      subject.migrate
      plan_year.reload
      enrollment.reload
    end

    around do |example|
      ClimateControl.modify py_params do
        example.run
      end
    end

    it 'should cancel the plan year' do
      expect(plan_year.aasm_state).to eq 'canceled'
      expect(plan_year2.aasm_state).to eq 'active'
    end

    it 'should cancel the enrollment' do
      expect(enrollment.aasm_state).to eq 'coverage_canceled'
    end
  end
end
