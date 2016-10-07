require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_hbx_enrollment_member")
describe AddHbxEnrollmentMember do
  let(:given_task_name) { "add_hbx_enrollment_member" }
  subject { AddHbxEnrollmentMember.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creating new enrollment member record for an enrollment" do
    let(:person) { FactoryGirl.create(:person) }
    let(:person_two) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:enrollment) do 
      hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "individual")
      hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record - 30.days)
      hbx.save
      hbx
    end
    let(:family_member) { FactoryGirl.create(:family_member, family: family, person: person_two)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(enrollment.hbx_id.to_s)
      allow(ENV).to receive(:[]).with("family_member_id").and_return(family_member.id)
    end
    it "should create a new enrollment member record" do    
      expect(enrollment.hbx_enrollment_members.count).to eq 1
      subject.migrate
      enrollment.reload
      expect(enrollment.hbx_enrollment_members.count).to eq 2
    end

    it "should not create a new enrollment member record if it already exists under enrollment" do
      enrollment.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family_member.id, eligibility_date: TimeKeeper.date_of_record - 30.days)
      enrollment.save
      expect(enrollment.hbx_enrollment_members.count).to eq 2
      subject.migrate
      enrollment.reload
      expect(enrollment.hbx_enrollment_members.count).to eq 2
    end
  end
end




