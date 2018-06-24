require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_employer_staff_role_from_person")

describe RemoveEmployerStaffRoleFromPerson do
  let(:given_task_name) { "remove_employer_staff_role_from_person" }
  subject { RemoveEmployerStaffRoleFromPerson.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove_employer_staff_role_from_person" do

    let(:employer_staff_role) {FactoryGirl.create(:employer_staff_role)}
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(employer_staff_role.person.hbx_id)
      allow(ENV).to receive(:[]).with("employer_staff_role_id").and_return(employer_staff_role.id.to_s)
    end

    it "should remove employer staff role from the person" do
      person=employer_staff_role.person
      expect(person.employer_staff_roles.size).to eq 1
      expect(person.employer_staff_roles.first.is_active).to eq true
      subject.migrate
      person.reload
      employer_staff_role.reload
      expect(person.employer_staff_roles.size).to eq 1
      expect(person.employer_staff_roles.first.is_active).to eq false
      expect(person.employer_staff_roles.first.aasm_state).to eq 'is_closed'
    end
  end
end