require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_enrollment_review_status")

describe UpdateReviewStatus, dbclean: :after_each do
  subject { UpdateReviewStatus.new("update_enrollment_review_status", double(:current_scope => nil)) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:enrollment_with_nil_review) {
    FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record,
                       aasm_state: 'shopping',
                       review_status: nil )
  }
  let(:enrollment_with_existing_review) {
    FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record,
                       aasm_state: 'shopping',
                       review_status: "in review" )
  }

  before do
    allow(subject).to receive(:get_families).and_return([family])
  end
  context "enrollments with review_status equal nil" do
    before do
      family.active_household.hbx_enrollments<<enrollment_with_nil_review
      subject.migrate
    end
    it "updates review status with default incomplete status" do
      expect(enrollment_with_nil_review.review_status).to eq "incomplete"
    end
  end

  context "enrollments with existing review_status" do
    before :each do
      family.active_household.hbx_enrollments<<enrollment_with_existing_review
      subject.migrate
    end
    it "doesn't update review status if it is already exists" do
      expect(enrollment_with_existing_review.review_status).to eq "in review"
    end
  end


end
