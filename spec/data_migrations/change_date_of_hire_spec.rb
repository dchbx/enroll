require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_date_of_hire")
describe ChangeDateOfHire, dbclean: :after_each do
  describe "given a task name" do
    let(:given_task_name) { "change_date_of_hire" }
    subject {ChangeDateOfHire.new(given_task_name, double(:current_scope => nil)) }
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "Change doh for employee role" do
    subject {ChangeDateOfHire.new("change_date_of_hire", double(:current_scope => nil)) }
    let(:person_with_employee_role) { FactoryGirl.create(:person, :with_employee_role) }
    let(:employer_profile_id){ person_with_employee_role.employee_roles.first.employer_profile_id }
    let(:date){ TimeKeeper.date_of_record - 5.days}
    before :each do
      allow(ENV).to receive(:[]).with('hbx_id').and_return "#{person_with_employee_role.hbx_id}"
      allow(ENV).to receive(:[]).with('new_doh').and_return date
      allow(ENV).to receive(:[]).with('employer_profile_id').and_return employer_profile_id
      subject.migrate
      person_with_employee_role.reload
    end
    it "should change dot of ce not in employment termination state" do
      expect(person_with_employee_role.employee_roles.first.hired_on).to eq date
    end
  end

  describe "Change doh for employee role for multiple employees" do
    subject {ChangeDateOfHire.new("change_date_of_hire", double(:current_scope => nil)) }
    let(:person_with_employee_role1) { FactoryGirl.create(:person, :with_employee_role) }
    let(:person_with_employee_role2) { FactoryGirl.create(:person, :with_employee_role) }
    let(:employer_profile_id){ person_with_employee_role1.employee_roles.first.employer_profile_id }
    let(:date){ TimeKeeper.date_of_record - 5.days}
    before :each do
      allow(ENV).to receive(:[]).with('hbx_id').and_return "#{person_with_employee_role1.hbx_id},#{person_with_employee_role2.hbx_id}"
      allow(ENV).to receive(:[]).with('new_doh').and_return date
      allow(ENV).to receive(:[]).with('employer_profile_id').and_return employer_profile_id
      person_with_employee_role2.employee_roles.first.update_attribute("employer_profile_id",employer_profile_id)
      subject.migrate
      person_with_employee_role1.reload
      person_with_employee_role2.reload
    end
    it "should change dot of ce not in employment termination state" do
      expect(person_with_employee_role1.employee_roles.first.hired_on).to eq date
      expect(person_with_employee_role2.employee_roles.first.hired_on).to eq date
    end
  end

  describe "Doesnot Change doh for employee role with different employee profile id" do
    subject {ChangeDateOfHire.new("change_date_of_hire", double(:current_scope => nil)) }
    let(:person_with_employee_role1) { FactoryGirl.create(:person, :with_employee_role) }
    let(:person_with_employee_role2) { FactoryGirl.create(:person, :with_employee_role) }
    let(:employer_profile_id){ person_with_employee_role1.employee_roles.first.employer_profile_id }
    let(:date){ TimeKeeper.date_of_record - 5.days}
    before :each do
      allow(ENV).to receive(:[]).with('hbx_id').and_return "#{person_with_employee_role1.hbx_id},#{person_with_employee_role2.hbx_id}"
      allow(ENV).to receive(:[]).with('new_doh').and_return date
      allow(ENV).to receive(:[]).with('employer_profile_id').and_return employer_profile_id
      subject.migrate
      person_with_employee_role1.reload
      person_with_employee_role2.reload
    end
    it "should change dot of ce not in employment termination state" do
      expect(person_with_employee_role1.employee_roles.first.hired_on).to eq date
      expect(person_with_employee_role2.employee_roles.first.hired_on).to_not eq date
    end
  end
end