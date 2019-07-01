require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_existing_family_member_as_dependent_to_enrollment")

describe AddExistingFamilyMemberAsDependentToEnrollment, dbclean: :after_each do
  subject { AddExistingFamilyMemberAsDependentToEnrollment.new("remove dependent from ee enrollment", double(:current_scope => nil)) }
  let(:family){FactoryBot.create(:family,:with_primary_family_member)}
  let(:person) { FactoryBot.create(:person) }
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment){FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member], family: family, household:family.active_household)}

  let(:family_member){FactoryBot.create(:family_member, family: family,is_primary_applicant: false, is_active: true, person: person)}
  context "won't add enrollment memeber if not found hbx_enrollment" do
    it "won't add enrollment memeber if not found hbx_enrollment" do
      ClimateControl.modify hbx_enrollment_id:'',family_member_id: family_member.id,coverage_begin:"2016-01-01" do 
        family.add_family_member(person)
        family_member_id=family_member.id
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
      end
    end
  end

  context "will add enrollment memeber if find hbx_enrollment_" do
    it "will add enrollment memeber if found hbx_enrollment" do
      ClimateControl.modify hbx_enrollment_id:hbx_enrollment.id,family_member_id: family_member.id,coverage_begin:"2016-01-01" do 
        family.add_family_member(person)
        family_member_id=family_member.id
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 1
      end
    end
    it "will add enrollment memeber with coverage start on date" do
      ClimateControl.modify hbx_enrollment_id:hbx_enrollment.id,family_member_id: family_member.id,coverage_begin:"2016-01-01" do 
        family.add_family_member(person)
        family_member_id=family_member.id
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).size).to eq 0
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.hbx_enrollment_members.where(applicant_id:family_member_id).first.coverage_start_on).to eq Date.new(2016,1,1)
      end
    end
  end
end

