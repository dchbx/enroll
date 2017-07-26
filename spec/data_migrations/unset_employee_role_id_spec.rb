require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "unset_employee_role_id")
describe UnsetEmplyeeRoleId, dbclean: :after_each do
  let(:given_task_name) { "unset_employee_role_id" }
  subject { UnsetEmplyeeRoleId.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "case with no found person" do
    before :each do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("")
    end
    it "found no person with given hbx_id" do
      expect{subject.migrate}.to raise_error("some error person with hbx_id:"" not found")
    end
  end
  describe "unset employee role", dbclean: :after_each do
    let(:person) { family.primary_family_member.person }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, household: family.active_household,id:"1", kind:"individual", employee_role_id: "1234")}
    let!(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household,id:"2", kind:"employer_sponsored", employee_role_id: "1234")}
    before(:each) do
      person.update_attributes(hbx_id: "1111")
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end
    it "should unset the ee_role_id of hbx_enrollment with individual kind" do
      expect(family.active_household.hbx_enrollments.size).to eq 2
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.size).to eq 2
      expect(family.active_household.hbx_enrollments.where(id:"1").first.employee_role_id).to eq nil
    end
    it "should keep the ee_role_id of hbx_enrollment with non-individual kind" do
      expect(family.active_household.hbx_enrollments.size).to eq 2
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.size).to eq 2
      expect(family.active_household.hbx_enrollments.where(id:"2").first.employee_role_id).to eq "1234"
    end
  end
end
