require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")

describe ChangeEnrollmentDetails do

  def actual_result(term_enrollment, val)
    case val
    when "aasm_state"
      term_enrollment.aasm_state
    when "terminated_on"
      term_enrollment.terminated_on
    when "termination_submitted_on"
      term_enrollment.termination_submitted_on
    end
  end

  let(:given_task_name) { "change_enrollment_details" }
  subject { ChangeEnrollmentDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing enrollment attributes" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:term_enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("new_effective_on").and_return(hbx_enrollment.effective_on + 1.month)
      allow(ENV).to receive(:[]).with("action").and_return "change_effective_date"
    end

    it "should change effective on date" do
      effective_on = hbx_enrollment.effective_on
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.effective_on).to eq effective_on + 1.month
    end

    it "should move enrollment to enrolled status from canceled status" do
      allow(ENV).to receive(:[]).with("action").and_return "revert_cancel"
      hbx_enrollment.cancel_coverage!
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
    end

    context "revert enrollment termination" do

      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(term_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "revert_termination"
        subject.migrate
        term_enrollment.reload
      end

      shared_examples_for "revert termination" do |val, result|
        it "should equals #{result}" do
          expect(actual_result(term_enrollment, val)).to eq result
        end
      end

      it_behaves_like "revert termination", "aasm_state", "coverage_enrolled"
      it_behaves_like "revert termination", "terminated_on", nil
      it_behaves_like "revert termination", "termination_submitted_on", nil
    end


    context "terminate enrollment with given termination date" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "terminate"
        allow(ENV).to receive(:[]).with("terminated_on").and_return "01/01/2016"
        subject.migrate
        hbx_enrollment.reload
      end

      shared_examples_for "termination" do |val, result|
        it "should equals #{result}" do
          expect(actual_result(hbx_enrollment, val)).to eq result
        end
      end

      it_behaves_like "termination", "aasm_state", "coverage_terminated"
      it_behaves_like "termination", "terminated_on", Date.strptime("01/01/2016", "%m/%d/%Y")

    end

    context "it should cancel the enrollment" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "cancel"
        subject.migrate
        hbx_enrollment.reload
      end

      it "should cancel the enrollment" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
