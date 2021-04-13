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

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family)}
    let(:hbx_enrollment2) { FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family)}
    let(:term_enrollment) { FactoryBot.create(:hbx_enrollment, :terminated, household: family.active_household, family: family)}
    let(:term_enrollment2) { FactoryBot.create(:hbx_enrollment, :terminated, household: family.active_household, family: family)}
    let(:term_enrollment3) { FactoryBot.create(:hbx_enrollment, :terminated, household: family.active_household, kind: "individual", family: family)}
    let(:new_plan) { FactoryBot.create(:plan) }
    let(:new_benefit_group) { FactoryBot.create(:benefit_group) }

    it "should change effective on date" do
      ClimateControl.modify hbx_id: "#{hbx_enrollment.hbx_id},#{hbx_enrollment2.hbx_id}", new_effective_on: "#{hbx_enrollment.effective_on + 1.month}", action: "change_effective_date" do 
          effective_on = hbx_enrollment.effective_on
          subject.migrate
          hbx_enrollment.reload
          hbx_enrollment2.reload
          expect(hbx_enrollment.effective_on).to eq (effective_on + 1.month)
          expect(hbx_enrollment2.effective_on).to eq (effective_on + 1.month)
        end
    end

    it "should move enrollment to enrolled status from canceled status" do
      ClimateControl.modify hbx_id: "#{hbx_enrollment.hbx_id},#{hbx_enrollment2.hbx_id}", new_effective_on: "#{hbx_enrollment.effective_on + 1.month}", action: "revert_cancel" do 
        hbx_enrollment.cancel_coverage!
        subject.migrate
        hbx_enrollment.reload
        hbx_enrollment2.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
        expect(hbx_enrollment2.aasm_state).to eq "coverage_enrolled"
      end
    end

    context "revert enrollment termination" do
      
      shared_examples_for "revert termination" do |val, result|
        it "should equals #{result}" do
          ClimateControl.modify hbx_id:"#{term_enrollment.hbx_id},#{term_enrollment2.hbx_id}", action: "revert_termination" do 
            subject.migrate
            term_enrollment.reload
            term_enrollment2.reload
            expect(actual_result(term_enrollment, val)).to eq result
            expect(actual_result(term_enrollment2, val)).to eq result
          end
        end
      end

      it_behaves_like "revert termination", "aasm_state", "coverage_enrolled"
      it_behaves_like "revert termination", "terminated_on", nil
      it_behaves_like "revert termination", "termination_submitted_on", nil
    end

    context "revert enrollment termination for individual enrollment" do
      before do
        ClimateControl.modify hbx_id:"#{term_enrollment3.hbx_id}", action: "revert_termination" do 
          subject.migrate
          term_enrollment3.reload
        end
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
      
      shared_examples_for "termination" do |val, result|
        it "should equals #{result}" do
          ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", action: "terminate",terminated_on: "01/01/2016" do 
            subject.migrate
            hbx_enrollment.reload
           expect(actual_result(hbx_enrollment, val)).to eq result
          end
        end
      end

      it_behaves_like "termination", "aasm_state", "coverage_terminated"
      it_behaves_like "termination", "terminated_on", Date.strptime("01/01/2016", "%m/%d/%Y")

    end


    context "change enrollment aasm state" do

      let(:benefit_application) { ::BenefitSponsors::BenefitApplications::BenefitApplication.new }
      let(:benefit_package) { ::BenefitSponsors::BenefitPackages::BenefitPackage.new }

      before do
        hbx_enrollment.update_attributes(sponsored_benefit_package_id: benefit_package.id)
      end

      
      it "should change the aasm state " do
        ClimateControl.modify hbx_id: hbx_enrollment.hbx_id.to_s, action: "change_enrollment_status", new_aasm_state: "move_to_enrolled" do
          hbx_enrollment.update_attribute('aasm_state', 'unverified')
          hbx_enrollment.reload
          allow(::BenefitSponsors::BenefitPackages::BenefitPackage).to receive(:find).and_return(benefit_package)
          allow(benefit_package).to receive(:benefit_application).and_return(benefit_application)
          expect(hbx_enrollment.may_move_to_enrolled?).to eq true
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
        end
      end

    end

    context "it should cancel the enrollment when it is eligible for cancelling" do

      it "should cancel the enrollment when it is eligible for cancelling" do
        ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", action: "cancel" do 
          expect(hbx_enrollment.may_cancel_coverage?).to eq true
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
        end
      end
      it "should not cancel the enrollment when it is not eligible for cancelling" do
        hbx_enrollment.update_attributes(aasm_state: "coverage_expired")
        expect(hbx_enrollment.may_cancel_coverage?).to eq false
        original_status = hbx_enrollment.aasm_state
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).not_to eq "coverage_canceled"
        expect(hbx_enrollment.aasm_state).to eq original_status
      end
    end

    context "generate_hbx_signature" do
      
      it "should have a enrollment_signature" do
        ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", action: "generate_hbx_signature" do 
          hbx_enrollment.update_attribute(:enrollment_signature, "")
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.enrollment_signature.present?).to be_truthy
        end
      end
    end

    context "expire the enrollment" do
      
      it "should expire the enrollment" do
        ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", action: "expire_enrollment" do 
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_expired"
        end
      end
    end

    context "change the plan of enrollment" do
      
      it "should change the plan of enrollment" do
        ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", action: "change_plan",new_product_id: new_plan.id do 
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.product_id).to eq new_plan.id
        end
      end
    end

    context "change the benefit group of enrollment" do
      it "should change the benefit group of enrollment" do
        ClimateControl.modify hbx_id:"#{hbx_enrollment.hbx_id}", new_sponsored_benefit_package_id: new_benefit_group.id, action: "change_benefit_group" do 
          subject.migrate
          hbx_enrollment.reload 
          expect(hbx_enrollment.sponsored_benefit_package_id).to eq new_benefit_group.id
        end
      end
    end
  end
end
