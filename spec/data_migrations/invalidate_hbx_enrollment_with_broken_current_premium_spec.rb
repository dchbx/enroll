require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "invalidate_hbx_enrollment_with_broken_current_premium")

describe InvalidateHbxEnrollmentWithBrokenCurrentPremium do

  let(:given_task_name) { "invalidate_hbx_enrollment_with_broken_current_premium" }
  subject { InvalidateHbxEnrollmentWithBrokenCurrentPremium.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "total premium" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household) }

    context "void enrollment" do
      before :each do
        hbx_enrollment.update_attributes!(:aasm_state => "inactive")
        hbx_enrollment.stub(:total_premium).and_raise(StandardError.new("error"))
      end

      it "should invalidate enrollment" do
        ClimateControl.modify :person_hbx_id => family.primary_person.hbx_id.to_s do
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq("void")
        end
      end
    end

    context "active enrollment" do
      before :each do
        hbx_enrollment.update_attributes!(:aasm_state => "coverage_selected")
        hbx_enrollment.stub(:total_premium).and_raise(StandardError.new("error"))
      end

      it "should not invalidate active enrollment" do
        ClimateControl.modify :person_hbx_id => family.primary_person.hbx_id.to_s do
          hbx_enrollment.stub(:total_premium).and_raise(StandardError.new("error"))
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq("coverage_selected")
        end
      end
    end
  end
end
