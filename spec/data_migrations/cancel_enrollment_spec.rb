require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'cancel_enrollment')

describe CancelEnrollment, dbclean: :after_each do

  let(:given_task_name) { 'cancel_enrollment' }
  subject { CancelEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  describe 'change enrollment status to coverage_canceled' do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}

    it 'should change status of the enrollment' do
      ClimateControl.modify hbx_id: hbx_enrollment.hbx_id do
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq 'coverage_canceled'
      end
    end
  end
end
