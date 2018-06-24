require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_one_ce_from_er")

describe RemoveOneCeFromEr, dbclean: :after_each do

  let(:given_task_name) { "remove_one_ce_from_er" }
  subject { RemoveOneCeFromEr.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove one cenesus employee from employer roaster" do
    subject {RemoveOneCeFromEr.new("remove_one_ce_from_er", double(:current_scope => nil)) }
      let(:person) { FactoryGirl.create(:person, :with_employee_role) }
      let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
      let(:household) { FactoryGirl.create(:household, family: person.primary_family) }
      let(:census_employee){ FactoryGirl.create(:census_employee, dob: TimeKeeper.date_of_record - 30.years)}
      let(:employee_role) {FactoryGirl.create(:employee_role)}
      before :each do
        allow(ENV).to receive(:[]).with('census_employee_id').and_return census_employee.id
        allow(employee_role).to receive(:census_employee_id).and_return census_employee.id
        person.employee_roles[0].update_attributes(census_employee_id: census_employee.id)
        census_employee.update_attributes(employee_role_id: person.employee_roles[0].id)
      end
      
      it "should remove one census_employee" do
        ce_id = census_employee.id
        subject.migrate
        expect(CensusEmployee.where(id: ce_id).first).to eq nil
      end

      it "should remove employee role" do
        ce_id = census_employee.id
        ee_id = census_employee.employee_role_id
        expect(person.primary_family.latest_household.hbx_enrollments).to eq []
        subject.migrate
        expect(EmployeeRole.find(ee_id)).to eq nil
      end    
  end
end
