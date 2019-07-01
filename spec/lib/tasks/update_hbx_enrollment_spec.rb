require 'rails_helper'
Rake.application.rake_require "tasks/update_hbx_enrollment"
Rake::Task.define_task(:environment)

RSpec.describe 'Update HBX Enrollments carrier profile id from plan', :type => :task, dbclean: :after_each do
  let!(:families) { FactoryBot.create_list(:family, 10, :with_primary_family_member) }
  let!(:hbx_enrollments) do
    Family.all.each do |family|
      enrollment = FactoryBot.create(
        :hbx_enrollment,
        family: family,
        household: family.active_household,
        carrier_profile_id: nil
      )
    end
  end
  let(:plan) { instance_double(Plan, id: "1", carrier_profile_id: "2") }
  context "invoking rake" do
    before :each do
      allow_any_instance_of(HbxEnrollment).to receive(:plan).and_return(plan)
      allow_any_instance_of(HbxEnrollment).to receive(:plan_id).and_return(plan.id)
    end

    it "should update carrier profile ids from plan" do
      expect(HbxEnrollment.first.carrier_profile_id).to eq(nil)
      Rake::Task['update_hbx:carrier_profile_id'].invoke
      HbxEnrollment.each do |enrollment|
        expect(enrollment.carrier_profile_id).to eq("2")
      end
    end
  end
end
