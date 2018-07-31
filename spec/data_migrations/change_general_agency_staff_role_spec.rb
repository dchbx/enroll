require "rails_helper"
if ExchangeTestingConfigurationHelper.general_agency_enabled?
require File.join(Rails.root, "app", "data_migrations", "change_general_agency_staff_role")

describe ChangeGeneralAgencyStaffRole, dbclean: :after_each do
  let(:given_task_name) { "change_general_agency_staff_role" }
  subject { ChangeGeneralAgencyStaffRole.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the general agency staff role" do
    let(:general_agency_staff_role) { FactoryGirl.create(:general_agency_staff_role) }
    let(:incorrect_person) {FactoryGirl.create(:person) }
    let(:correct_person) { FactoryGirl.create(:person) }
    before(:each) do
        allow(ENV).to receive(:[]).with("incorrect_person_hbx_id").and_return(incorrect_person.hbx_id)
        allow(ENV).to receive(:[]).with("correct_person_hbx_id").and_return(correct_person.hbx_id)   
        incorrect_person.general_agency_staff_roles << general_agency_staff_role
    end

      it "should add general agency staff role to the correct_person account" do
          expect(incorrect_person.general_agency_staff_roles.present?).to be_truthy
          expect(correct_person.general_agency_staff_roles.present?).to eq false
          subject.migrate
          incorrect_person.reload
          correct_person.reload
          expect(correct_person.general_agency_staff_roles.count).to eq 1 
          expect(incorrect_person.general_agency_staff_roles.present?).to eq false
      end
  end
end
end
