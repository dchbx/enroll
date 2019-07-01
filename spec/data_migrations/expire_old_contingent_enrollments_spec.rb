require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "expire_old_contingent_enrollments")

describe ExpireOldContingentEnrollments, dbclean: :after_each do

  let(:given_task_name) { "expire_old_contingent_enrollments" }
  subject { ExpireOldContingentEnrollments.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrate hbx enrollment" do
    let!(:person)           { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family)           { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:hbx_enrollment)   { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: "enrolled_contingent", household: family.active_household,
                              effective_on: TimeKeeper.date_of_record.prev_year, kind: "individual") }

    context "for successful migration" do
      before :each do
        subject.migrate
        hbx_enrollment.reload
      end

      it "should update the aasm_state to coverage_expired" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_expired"
      end

      it "should add new workflow_state_transition instance for hbx_enrollment" do
        expect(hbx_enrollment.workflow_state_transitions.first.comment).to eq "Expired inactive enrollments from previous year via data migration"
        expect(hbx_enrollment.workflow_state_transitions.first.from_state).to eq "enrolled_contingent"
        expect(hbx_enrollment.workflow_state_transitions.first.to_state).to eq "coverage_expired"
      end
    end

    context "for unsuccessful migration" do
      before :each do
        hbx_enrollment.update_attributes!(aasm_state: "shopping")
        subject.migrate
      end

      it "should do nothing if the enrollment is not in enrolled_contingent" do
        expect(hbx_enrollment.aasm_state).to eq "shopping"
      end
    end
  end
end
