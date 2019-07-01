require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "reset_due_dates_for_outstanding_consumers")
describe ResetDueDatesForOutstandingConsumers, dbclean: :after_each do

  let(:given_task_name) { "remove_enrolled_contingent_state" }
  subject { ResetDueDatesForOutstandingConsumers.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "reset due date for outstanding consumer" do
    let!(:person)           { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role)     { person.consumer_role }
    let!(:family)           { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:hbx_enrollment)   { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: "coverage_selected", effective_on: TimeKeeper.date_of_record,
                                                 household: family.active_household, kind: "individual") }
    let!(:hbx_enrollment_member) { FactoryBot.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment,
                                                      eligibility_date: (TimeKeeper.date_of_record - 2.months), coverage_start_on: (TimeKeeper.date_of_record - 2.months),
                                                      is_subscriber: true, applicant_id: family.primary_applicant.id) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment,
                                                       eligibility_date: (TimeKeeper.date_of_record - 2.months), coverage_start_on: (TimeKeeper.date_of_record - 2.months),
                                                       is_subscriber: false, applicant_id: family.family_members[1].id) }
    let(:dep_person) { family.family_members[1].person }
    let!(:dep_consumer_role) { FactoryBot.create(:consumer_role, person: dep_person) }
    let!(:dep_imt) { FactoryBot.create :individual_market_transition, person: dep_person }
    let!(:dep_person1) { family.family_members[2].person }
    let!(:dep_consumer_role1) { FactoryBot.create(:consumer_role, person: dep_person1) }
    let!(:dep_imt1) { FactoryBot.create :individual_market_transition, person: dep_person1 }


    context "it should update the due. date and enrollment state" do
      before :each do
        consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        subject.migrate
        hbx_enrollment.reload
        consumer_role.verification_types.map(&:reload)
      end

      it "should return is_any_member_outstanding? as true" do
        expect(hbx_enrollment.is_any_member_outstanding?).to be_truthy
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
      end

      it "should update the verification_types" do
        expect(consumer_role.verification_types[0].due_date).to be_truthy
      end
    end

    context "it should not update the due date if none of the enrolled members are outstanding" do

      before :each do
        consumer_role.update_attributes!(aasm_state: "verified")
        subject.migrate
        hbx_enrollment.reload
        consumer_role.verification_types.map(&:reload)
      end

      it "should change the aasm_state" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
      end

      it "should not update the verifcation_types" do
        expect(consumer_role.verification_types[0].due_date).to be_falsy
      end
    end

    context "it should consider only dep in verification outstanding" do
      before :each do
        dep_consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        subject.migrate
        hbx_enrollment.reload
        dep_consumer_role.verification_types.map(&:reload)
      end

      it "should update the aasm_state to verification type's due date" do
        dep_consumer_role.update_attributes!(aasm_state: "verification_outstanding")
        dep_consumer_role.verification_types[2].update_attribute("validation_status","verification_outstanding")
        expect(hbx_enrollment.is_any_member_outstanding?).to be_truthy
      end

      it "should update the verifcation_types" do
        expect(dep_consumer_role.verification_types[0].due_date).to be_truthy
      end
    end
  end
end
