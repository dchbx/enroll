require 'rails_helper'

require File.join(Rails.root,'app','data_migrations','update_waiver_reason')

describe UpdateWaiverReason, dbclean: :after_each do 
  let(:given_task_name) {'update_waiver_reason'}
  subject { UpdateWaiverReason.new(given_task_name, double(:current_scope=>nil))}

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'update waiver reason' do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, waiver_reason: 'this is the reason')}

    it 'should update waiver reason' do
      ClimateControl.modify id: "#{hbx_enrollment.hbx_id}", waiver_reason: 'waiver_reason' do
        expect(hbx_enrollment.waiver_reason).to eq 'this is the reason'
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.waiver_reason).to eq 'waiver_reason'
      end
    end
  end
end


