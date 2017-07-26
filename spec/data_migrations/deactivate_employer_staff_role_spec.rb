require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_employer_staff_role")

describe DeactivateEmployerStaffRole do
  let(:given_task_name) { "deactivate_employer_staff_role" }
  subject { DeactivateEmployerStaffRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deactivate employer staff role" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile)}

    let(:employer_staff_role) {FactoryGirl.build(:employer_staff_role, aasm_state:'is_active', employer_profile_id: employer_profile.id)}
    let(:person) { FactoryGirl.create(:person,employer_staff_roles:[employer_staff_role])}
    let(:organization) { FactoryGirl.create(:organization, employer_profile:employer_profile)}
    let(:staff_role) { Person.by_hbx_id(person.hbx_id).first.employer_staff_roles.detect{|role| role.employer_profile_id.to_s == employer_profile.id.to_s} }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end

    it "should update aasm state of staff role" do
      expect(staff_role.aasm_state).to eq "is_active"
      subject.migrate
      staff_role.reload
      expect(staff_role.aasm_state).to eq "is_closed"
    end
  end

end