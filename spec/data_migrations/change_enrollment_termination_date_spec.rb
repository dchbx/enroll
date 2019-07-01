require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_enrollment_termination_date')

describe ChangeEnrollmentTerminationDate, dbclean: :after_each do

  let(:given_task_name) { 'change_enrollment_effective_on_date' }
  subject { ChangeEnrollmentTerminationDate.new(given_task_name, double(:current_scope => nil)) }
   let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
   let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,terminated_on:Date.today,household: family.active_household, family: family)}
   let!(:py_params) {{hbx_id: hbx_enrollment.hbx_id, new_termination_date: (hbx_enrollment.terminated_on + 1.month).to_s }}

  describe 'given a task name'do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  around do |example|
    ClimateControl.modify py_params do
      example.run
    end
  end

  describe 'changing enrollment termiantion date' do
    it 'should change effective on date' do
      terminated_on = hbx_enrollment.terminated_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.terminated_on).to eq terminated_on + 1.month
    end
  end

  describe 'changing enrollment member termiantion date' do
    let!(:hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment:hbx_enrollment,applicant_id: family.family_members.first.id,is_subscriber: true, eligibility_date:Date.today )}

    it 'should change effective on date' do
      terminated_on = hbx_enrollment.terminated_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.first.coverage_end_on).to eq terminated_on + 1.month
    end
  end
end
