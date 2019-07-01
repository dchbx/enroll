require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'cancel_policy')

describe CancelPolicy do

  let(:given_task_name) { 'cancel_policy' }
  subject { CancelPolicy.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing aasm state' do
    
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}

    it 'should change aasm state to canceled' do
      ClimateControl.modify hbx_id: hbx_enrollment.hbx_id do
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq 'coverage_canceled'
      end
    end
  end
end
