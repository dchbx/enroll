require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_incorrect_termination_date_in_enrollment")

describe ChangeIncorrectTerminationDateInEnrollment do

  subject { ChangeIncorrectTerminationDateInEnrollment.new("change incorrect termination date in enrollment", double(:current_scope => nil)) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

  let(:enrollment_1) {
    FactoryGirl.create(
       :hbx_enrollment,
       household: family.active_household,
       coverage_kind: "health",
       effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
       enrollment_kind: "open_enrollment",
       kind: "individual",
       submitted_at: TimeKeeper.date_of_record,
       aasm_state: 'shopping',
       review_status: nil
    )

  }

  let(:enrollment_2) {
    FactoryGirl.create(
      :hbx_enrollment,
      household: family.active_household,
      coverage_kind: "health",
      effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
      enrollment_kind: "open_enrollment",
      kind: "individual",
      submitted_at: TimeKeeper.date_of_record,
      aasm_state: 'coverage_terminated',
      terminated_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
      review_status: "in review"
    )
  }

  context "enrollments with review_status equal nil" do
    let(:date) { (TimeKeeper.date_of_record.next_month.beginning_of_month + 2.days).to_s }

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return enrollment_1.hbx_id
      allow(ENV).to receive(:[]).with('termination_date').and_return date
      family.active_household.hbx_enrollments << enrollment_1
      subject.migrate
    end

    it "should not modify hbx_enrollment not in terminated state" do
      enrollment = HbxEnrollment.by_hbx_id(enrollment_1.hbx_id).first
      expect(enrollment.aasm_state).to eq "shopping"
      expect(enrollment.terminated_on).to eq nil
    end

  end

  context "enrollments with existing review_status" do
    let(:date) { (TimeKeeper.date_of_record.next_month.beginning_of_month + 2.days).to_s }

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return enrollment_2.hbx_id
      allow(ENV).to receive(:[]).with('termination_date').and_return date
      family.active_household.hbx_enrollments << enrollment_2
      subject.migrate
      family.reload
    end

    it "should modify hbx_enrollment in terminated state" do
      enrollment = HbxEnrollment.by_hbx_id(enrollment_2.hbx_id).first
      expect(enrollment.aasm_state).to eq "coverage_terminated"
      expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record.next_month.beginning_of_month + 2.days
    end

  end
end
