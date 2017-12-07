require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_subscriber_to_enrollment")

describe AddSubscriberToEnrollment, dbclean: :after_each do
  let(:given_task_name) { "add_subscriber_to_enrollment" }
  subject { AddSubscriberToEnrollment.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "will add subscriber if no subrscriber exists for the given hbx_enrollment" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, is_subscriber:true,applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let(:hbx_enrollment_member2){ FactoryGirl.build(:hbx_enrollment_member, is_subscriber:false,applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,hbx_enrollment_members:[hbx_enrollment_member1,hbx_enrollment_member2], household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("policy_hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_enrollment_member_id").and_return(hbx_enrollment_member2.id)
    end
    it "should not add subscriber" do
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.subscriber).not_to eq hbx_enrollment_member2
      expect(hbx_enrollment.subscriber).to eq hbx_enrollment_member1
    end
  end
  describe "will not add subscriber if no enrollment found" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, is_subscriber:false,applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,hbx_enrollment_members:[hbx_enrollment_member], household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("policy_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("hbx_enrollment_member_id").and_return(hbx_enrollment.hbx_enrollment_members.first.id)
    end
    it "should not add subscriber" do
      hbx_enrollment_member=hbx_enrollment.subscriber
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.subscriber).to eq nil
    end
  end
  describe "will not add subscriber if no enrollment found" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, is_subscriber:false,applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,hbx_enrollment_members:[hbx_enrollment_member], household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("policy_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("hbx_enrollment_member_id").and_return(hbx_enrollment.hbx_enrollment_members.first.id)
    end
    it "should not add subscriber" do
      hbx_enrollment_member=hbx_enrollment.subscriber
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.subscriber).to eq nil
    end
  end
end
