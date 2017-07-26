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
    let(:household) { FactoryGirl.create(:household, family: family) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:family_member1) { FactoryGirl.create(:family_member, family: household.family) }
    let(:family_member2) { FactoryGirl.create(:family_member, family: household.family) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: household) }
    let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    context "it should not remove the hbx_enrollment" do
      let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      before(:each) do
        allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("hbx_enrollment_member_id").and_return(hbx_enrollment_member1.id)
      end
      it "should not remove the hbx_enrollment" do
        size=household.hbx_enrollments.size
        expect(household.hbx_enrollments.size).to eq size
        subject.migrate
        household.reload
        expect(household.hbx_enrollments.size).to eq size
      end
    end
    context "it should remove the related hbx_enrollment member" do
      let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
      before(:each) do
        allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("hbx_enrollment_member_id").and_return(hbx_enrollment_member1.id)
      end
      it "should remove the related hbx_enrollment_member from the hbx_enrollment" do
        size=hbx_enrollment.hbx_enrollment_members.size
        expect(hbx_enrollment.hbx_enrollment_members.size).to eq size
        subject.migrate
        household.reload
        expect(household.hbx_enrollments.first.hbx_enrollment_members.size).to eq size-1
      end
    end


  end
end
