require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  require File.join(Rails.root, "app", "data_migrations", "remove_resident_role")

  describe RemoveResidentRole do

    let(:given_task_name) {"remove_resident_role"}
    subject {RemoveResidentRole.new(given_task_name, double(:current_scope => nil))}

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "remove resident role for person with consumer and resident roles", dbclean: :after_each do
      let!(:person1) { FactoryBot.create(:person, :with_resident_role, hbx_id: '58e3dc7dqwewqewqe')} 
      let!(:person2) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:primary_family) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }
      let!(:ivl_enrollment) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: primary_family, household: primary_family.active_household,
                          kind: 'coverall', consumer_role_id: person2.consumer_role.id)
      end
      let!(:r_role) {FactoryBot.create(:resident_role, person: person2)}

      before(:each) do
        ClimateControl.modify :coverall_ids => "dfrwrwe23r,58e3dc7dqwewqewqe", :p_to_fix_id => nil do
          subject.migrate
          person1.reload
          person2.reload
        end
      end

      it "deletes the resident role for person2" do
        expect(person2.resident_role).to be_nil
      end

      it "does not delete the resident role for person1" do
        expect(person1.resident_role).not_to be_nil
      end

      it "sets the kind attribute on person2's enrollment to individual" do
        expect(person2.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
      end

      it "sets the resident_role_id on person2's enrollment to nil" do
        expect(person2.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
      end

      it "sets the consumer_role_id on person2's enrollment to be the consumer role of person2" do
        expect(person2.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person2.consumer_role.id)
      end
    end

    describe "remove resident role for person with coverall enrollment and no consumer_role", dbclean: :after_each do
      let!(:person1) {FactoryBot.create(:person, :with_resident_role, ssn: 123654321)}
      let!(:primary_family) {FactoryBot.create(:family, :with_primary_family_member, person: person1)}
      let!(:ivl_enrollment) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: primary_family, household: primary_family.active_household,
                          kind: 'coverall', resident_role_id: person1.resident_role.id)
      end
      let!(:ee_role) {FactoryBot.create(:employee_role, person: person1)}

      before(:each) do
        ClimateControl.modify :coverall_ids => "dfrwrwe23r,58e3dc7dqwewqewqe", :p_to_fix_id => nil do
          subject.migrate
          person1.reload
        end
      end


      it "deletes the resident role for person1" do
        expect(person1.resident_role).to be(nil)
      end

      it "creates a consumer role and associates it with person1" do
        expect(person1.consumer_role).not_to be_nil
      end

      it "sets the kind attribute of person1's enrollment to individual" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
      end

      it "sets the resident_role_id for person1's enrollment to nil" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
      end

      it "sets the consumer_role_id of person1's enrollmet to the new consumer_role.id associated with person1" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person1.consumer_role.id)
      end
    end

    describe "remove resident role for all family members with resident role and no consumer_role", dbclean: :after_each do
      let!(:person1) {FactoryBot.create(:person, :with_resident_role, ssn: 123654321)}
      let!(:dep1) {FactoryBot.create(:person, :with_resident_role, ssn: 123654322)}
      let!(:dep2) {FactoryBot.create(:person, :with_resident_role, ssn: 123654323)}
      let!(:primary_family) {FactoryBot.create(:family, :with_primary_family_member, person: person1)}
      let!(:fam_mem1) {FactoryBot.create(:family_member, family: primary_family)}
      let!(:ivl_enrollment) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: primary_family, household: primary_family.active_household,
                          kind: 'coverall', resident_role_id: person1.resident_role.id)
      end

      let!(:ee_role) {FactoryBot.create(:employee_role, person: person1)}
      let!(:hbx_mem1) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: ivl_enrollment, applicant_id: person1.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month)}
      let!(:fam_mem1) {FactoryBot.create(:family_member, family: primary_family, id: person1.id)}
      before(:each) do
        ClimateControl.modify :coverall_ids => "dfrwrwe23r,58e3dc7dqwewqewqe", :p_to_fix_id => nil do
          subject.migrate
          person1.reload
        end
      end

      it "deletes the resident role for person1" do
        expect(person1.resident_role).to be(nil)
      end

      it "creates a consumer role and associates it with person1" do
        expect(person1.consumer_role).not_to be_nil
      end

      it "sets the kind attribute of person1's enrollment to individual" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
      end

      it "sets the resident_role_id for person1's enrollment to nil" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
      end

      it "sets the consumer_role_id of person1's enrollmet to the new consumer_role.id associated with person1" do
        expect(person1.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person1.consumer_role.id)
      end
    end
  end
end
