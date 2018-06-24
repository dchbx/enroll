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
    when "termination_submitted_on"
      term_enrollment.generate_hbx_signature
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
    let(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:term_enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment2) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment3) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household, kind: "individual")}
    let(:new_plan) { FactoryGirl.create(:plan) }
    let(:new_benefit_group) { FactoryGirl.create(:benefit_group) }

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("#{hbx_enrollment.hbx_id},#{hbx_enrollment2.hbx_id}")
      allow(ENV).to receive(:[]).with("new_effective_on").and_return(hbx_enrollment.effective_on + 1.month)
      allow(ENV).to receive(:[]).with("action").and_return "change_effective_date"
    end

    it "should change effective on date" do
      effective_on = hbx_enrollment.effective_on
      subject.migrate
      hbx_enrollment.reload
      hbx_enrollment2.reload
      expect(hbx_enrollment.effective_on).to eq effective_on + 1.month
      expect(hbx_enrollment2.effective_on).to eq effective_on + 1.month
    end

    it "should move enrollment to enrolled status from canceled status" do
      allow(ENV).to receive(:[]).with("action").and_return "revert_cancel"
      hbx_enrollment.cancel_coverage!
      subject.migrate
      hbx_enrollment.reload
      hbx_enrollment2.reload
      expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
      expect(hbx_enrollment2.aasm_state).to eq "coverage_enrolled"
    end

    context "revert enrollment termination" do

      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return("#{term_enrollment.hbx_id},#{term_enrollment2.hbx_id}")
        allow(ENV).to receive(:[]).with("action").and_return "revert_termination"
        subject.migrate
        term_enrollment.reload
        term_enrollment2.reload
      end

      shared_examples_for "revert termination" do |val, result|
        it "should equals #{result}" do
          expect(actual_result(term_enrollment, val)).to eq result
          expect(actual_result(term_enrollment2, val)).to eq result
        end
      end

      it_behaves_like "revert termination", "aasm_state", "coverage_enrolled"
      it_behaves_like "revert termination", "terminated_on", nil
      it_behaves_like "revert termination", "termination_submitted_on", nil
    end

    context "revert enrollment termination for individual enrollment" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return("#{term_enrollment3.hbx_id}")
        allow(ENV).to receive(:[]).with("action").and_return "revert_termination"
        subject.migrate
        term_enrollment3.reload
      end

      shared_examples_for "revert termination" do |val, result|
        it "should equals #{result}" do
          expect(actual_result(term_enrollment3, val)).to eq result
        end
      end

      it_behaves_like "revert termination", "aasm_state", "coverage_selected"
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


    context "change enrollment aasm state" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "change_enrollment_status"
        allow(ENV).to receive(:[]).with("new_aasm_state").and_return "move_to_enrolled"
        hbx_enrollment.update_attribute("aasm_state","enrolled_contingent")
        hbx_enrollment.reload
      end

      it "should change the aasm state " do
        expect(hbx_enrollment.may_move_to_enrolled?).to eq true
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
      end

    end

    context "it should cancel the enrollment when it is eligible for cancelling" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "cancel"
      end

      it "should cancel the enrollment when it is eligible for cancelling" do
        expect(hbx_enrollment.may_cancel_coverage?).to eq true
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end
      it "should not cancel the enrollment when it is not eligible for cancelling" do
        hbx_enrollment.update_attributes(aasm_state:"coverage_terminated")
        expect(hbx_enrollment.may_cancel_coverage?).to eq false
        original_status = hbx_enrollment.aasm_state
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).not_to eq "coverage_canceled"
        expect(hbx_enrollment.aasm_state).to eq original_status
      end
    end

    context "generate_hbx_signature" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "generate_hbx_signature"
        hbx_enrollment.update_attribute(:enrollment_signature, "")
      end

      it "should have a enrollment_signature" do
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.enrollment_signature.present?).to be_truthy
      end
    end

    context "expire the enrollment" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("action").and_return "expire_enrollment"
        subject.migrate
        hbx_enrollment.reload
      end

      it "should expire the enrollment" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_expired"
      end
    end

    context "change the plan of enrollment" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("new_plan_id").and_return(new_plan.id)
        allow(ENV).to receive(:[]).with("action").and_return "change_plan"
        subject.migrate
        hbx_enrollment.reload
      end

      it "should change the plan of enrollment" do
        expect(hbx_enrollment.plan_id).to eq new_plan.id
      end
    end

    context "change the benefit group of enrollment" do
      before do
        allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
        allow(ENV).to receive(:[]).with("new_benefit_group_id").and_return(new_benefit_group.id)
        allow(ENV).to receive(:[]).with("action").and_return "change_benefit_group"
        subject.migrate
        hbx_enrollment.reload
      end

      it "should change the benefit group of enrollment" do
        expect(hbx_enrollment.benefit_group_id).to eq new_benefit_group.id
      end
    end
  end
end
