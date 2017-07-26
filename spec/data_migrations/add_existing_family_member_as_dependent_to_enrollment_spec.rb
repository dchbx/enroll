require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_existing_family_member_as_dependent_to_enrollment")

describe AddExistingFamilyMemberAsDependentToEnrollment, dbclean: :after_each do
  subject { AddExistingFamilyMemberAsDependentToEnrollment.new("remove dependent from ee enrollment", double(:current_scope => nil)) }
  let(:family){FactoryGirl.create(:family,:with_primary_family_member)}
  let(:person) { FactoryGirl.create(:person) }
  let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment){FactoryGirl.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member], household:family.active_household)}

  let(:family_member){FactoryGirl.create(:family_member, family: family,is_primary_applicant: false, is_active: true, person: person)}
  context "won't add enrollment memeber if not found hbx_enrollment" do
    before do
      allow(ENV).to receive(:[]).with("hbx_enrollment_id").and_return('')
      allow(ENV).to receive(:[]).with("family_member_id").and_return(family_member.id)
      allow(ENV).to receive(:[]).with("coverage_begin").and_return("2016-01-01")
      family.add_family_member(person)
    end
    it "won't add enrollment memeber if not found hbx_enrollment" do
      family_member_id=family_member.id
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
    end
  end

  context "will add enrollment memeber if find hbx_enrollment_" do
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_enrollment_id").and_return(hbx_enrollment.id)
      allow(ENV).to receive(:[]).with("family_member_id").and_return(family_member.id)
      allow(ENV).to receive(:[]).with("coverage_begin").and_return("2016-01-01")
      family.add_family_member(person)
    end
    it "will add enrollment memeber if found hbx_enrollment" do
      family_member_id=family_member.id
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 1
    end
    it "will add enrollment memeber with coverage start on date" do
      family_member_id=family_member.id
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).first.coverage_start_on).to eq Date.new(2016,1,1)
    end
  end
end
