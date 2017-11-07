require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_aasm_state_of_unverified_consumers")
describe ChangeAASMStateOfUnVerifiedConsumers, dbclean: :after_each do
  describe "given a task name" do
    let(:given_task_name) { "change_aasm_state_unverified_consumers" }
    subject {ChangeAASMStateOfUnVerifiedConsumers.new(given_task_name, double(:current_scope => nil)) }
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "census employee not in terminated state" do
    subject {ChangeAASMStateOfUnVerifiedConsumers.new("change_aasm_state_unverified_consumers", double(:current_scope => nil)) }
    let(:current_benefit_coverage_period) { OpenStruct.new(start_on: Date.new(2017,1,1), end_on: Date.new(2017,12,31)) }
    let(:renewal_plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.next_year.year, hios_id: "11111111122302-01", csr_variant_id: "01") }
    let(:current_plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id) }
    let(:primary_dob){ TimeKeeper.date_of_record.next_month - 57.years }
    let(:person) { FactoryGirl.create(:person, :with_consumer_role, dob: primary_dob) }
    let!(:family) {
      FactoryGirl.create(:family, :with_primary_family_member, :person => person)
    }
    let(:enrollment_members) { family.family_members }
    let(:coverage_kind) { 'health' }
    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
                         enrollment_members: enrollment_members,
                         household: family.active_household,
                         coverage_kind: coverage_kind,
                         effective_on: current_benefit_coverage_period.start_on,
                         kind: "individual",
                         plan_id: current_plan.id,
                         aasm_state: 'coverage_selected'
      )
    }
    let!(:aasm_state) { person.consumer_role.update_attribute("aasm_state","verification_outstanding")}

    it "should change aasm_state of enrollment" do
      subject.migrate
      enrollment.reload
      expect(enrollment.aasm_state).to eq "enrolled_contingent"
    end
  end
end