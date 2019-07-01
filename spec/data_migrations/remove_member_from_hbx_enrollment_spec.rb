require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_member_from_hbx_enrollment")

describe RemoveMemberFromHbxEnrollment, dbclean: :after_each do

  let(:given_task_name) { "remove_member_from_hbx_enrollment" }
  subject { RemoveMemberFromHbxEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "removing member from hbx_enrollment" do
    let(:household) { FactoryBot.create(:household, family: family) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:family_member1) { FactoryBot.create(:family_member, family: household.family) }
    let(:family_member2) { FactoryBot.create(:family_member, family: household.family) }
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: household, family: family) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    context "it should not remove the hbx_enrollment" do
      let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  
      it "should not remove the hbx_enrollment" do
        ClimateControl.modify enrollment_hbx_id: hbx_enrollment.hbx_id, hbx_enrollment_member_id: hbx_enrollment_member1.id do 
          size=hbx_enrollment.hbx_enrollment_members.size
          expect(hbx_enrollment.hbx_enrollment_members.size).to eq size
          subject.migrate
          household.reload
          expect(household.hbx_enrollments.first.hbx_enrollment_members.size).to eq size-1
        end
      end
    end
    context "it should remove the related hbx_enrollment member" do
      let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      
      it "should remove the related hbx_enrollment_member from the hbx_enrollment" do
        ClimateControl.modify enrollment_hbx_id: hbx_enrollment.hbx_id, hbx_enrollment_member_id: hbx_enrollment_member1.id do 
          size=hbx_enrollment.hbx_enrollment_members.size
          expect(hbx_enrollment.hbx_enrollment_members.size).to eq size
          subject.migrate
          household.reload
          expect(household.hbx_enrollments.first.hbx_enrollment_members.size).to eq size-1
        end
      end
    end
  end
end
