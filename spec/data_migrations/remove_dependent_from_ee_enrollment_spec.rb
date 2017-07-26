require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_dependent_from_ee_enrollment")

describe RemoveDependentFromEeEnrollment, dbclean: :after_each do
  subject { RemoveDependentFromEeEnrollment.new("remove dependent from ee enrollment", double(:current_scope => nil)) }
  let(:family){FactoryGirl.create(:family,:with_primary_family_member)}
  let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment){FactoryGirl.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member], household:family.active_household)}

  context "won't delete enrollment memeber if not found hbx_enrollment" do
    before do
      allow(ENV).to receive(:[]).with("enrollment_id").and_return('')
      allow(ENV).to receive(:[]).with("enrollment_member_id").and_return(hbx_enrollment.hbx_enrollment_members.first.id)
    end
    it "won't delete enrollment memeber if not found hbx_enrollment" do
      enrollment_member_id=hbx_enrollment.hbx_enrollment_members.first.id
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 1
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 1
    end
  end

  context "won't delete enrollment memeber if not found hbx_enrollment_member" do
    before do
      allow(ENV).to receive(:[]).with("enrollment_id").and_return(hbx_enrollment.id)
      allow(ENV).to receive(:[]).with("enrollment_member_id").and_return("")

    end
    it "won't delete enrollment memeber if not found hbx_enrollment" do
      enrollment_member_id=hbx_enrollment.hbx_enrollment_members.first.id
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 1
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 1
    end
  end

  context "will delete enrollment memeber if find hbx_enrollment_member within hbx_enrollment" do
    before do
      allow(ENV).to receive(:[]).with("enrollment_id").and_return(hbx_enrollment.id)
      allow(ENV).to receive(:[]).with("enrollment_member_id").and_return(hbx_enrollment.hbx_enrollment_members.first.id)

    end
    it "won't delete enrollment memeber if not found hbx_enrollment" do
      enrollment_member_id=hbx_enrollment.hbx_enrollment_members.first.id
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 1
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.where(id: enrollment_member_id).size).to eq 0
    end
  end
end
