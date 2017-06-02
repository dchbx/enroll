require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "enrollment_data_update")

describe EnrollmentDataUpdate do

  let(:given_task_name) { "enrollment data update" }
  subject { EnrollmentDataUpdate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "ivl enrollment case " do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, kind:"individual", household: family.active_household,effective_on: 1.month.ago.to_date, aasm_state: "coverage_canceled")}
    let!(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, kind:"individual", household: family.active_household,effective_on: 1.month.ago.to_date+1.days,submitted_at:1.month.ago.to_date-1.days)}
    let!(:hbx_enrollment_member1) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment1,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1))}
    let!(:hbx_enrollment_member2) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment2,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1))}

    it "should change enrollment 1's state" do
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id:hbx_enrollment1.id).first.aasm_state).to eq "coverage_terminated"
    end

    it "should not change enrollment 1's state if enrollment 1's effective date not after enrollment 2.submitted date" do
      hbx_enrollment2.update_attributes(submitted_at: hbx_enrollment1.effective_on)
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id:hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end

    it "should not change enrollment 1's state if enrollment 1's effective date not before enrollment 2's effective date" do
      hbx_enrollment2.update_attributes(effective_on: hbx_enrollment1.effective_on)
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id:hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end

    it "should not change enrollment 1's state if enrollment 1's and enrollment 2's are of different kinds" do
      hbx_enrollment2.update_attributes(kind:"employer_sponsored")
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id:hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end

  end

  describe "shop enrollment case " do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, :shop, benefit_group: benefit_group , household: family.active_household,effective_on: 1.month.ago.to_date, terminated_on: TimeKeeper.datetime_of_record-1, aasm_state: "coverage_canceled") }
    let!(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, :shop, benefit_group: benefit_group, household: family.active_household,effective_on: 1.month.ago.to_date+1.days,submitted_at:1.month.ago.to_date-1.days) }
    let!(:hbx_enrollment_member1) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment1,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1)) }
    let!(:hbx_enrollment_member2) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment2,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1)) }

    it "should change enrollment 1's state to coverage terminataed" do
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id: hbx_enrollment1.id).first.aasm_state).to eq "coverage_terminated"
    end

    it "should change enrollment 1's state to coverate termination pending" do
      hbx_enrollment1.update_attributes(terminated_on: TimeKeeper.datetime_of_record+1)
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id: hbx_enrollment1.id).first.aasm_state).to eq "coverage_termination_pending"
    end

    it "should not change enrollment 1's state if enrollment 1's effective date not after enrollment 2.submitted date" do
      hbx_enrollment2.update_attributes(submitted_at: hbx_enrollment1.effective_on)
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id: hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end

    it "should not change enrollment 1's state if enrollment 1's effective date not before enrollment 2's effective date" do
      hbx_enrollment2.update_attributes(effective_on: hbx_enrollment1.effective_on)
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id: hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end

    it "should not change enrollment 1's state if enrollment 1's and enrollment 2's are of different kinds" do
      hbx_enrollment2.update_attributes(kind:"individual")
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id: hbx_enrollment1.id).first.aasm_state).not_to eq "coverage_terminated"
    end
  end

end
