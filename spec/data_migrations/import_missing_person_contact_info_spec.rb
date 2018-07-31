require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "import_missing_person_contact_info")

describe ImportMissingPersonContactInfo do
  subject { ImportMissingPersonContactInfo.new("import_missing_person_Contact_info", double(current_scope: nil)) }

  let(:census_employee) { FactoryGirl.create(:census_employee) }
  let(:employer_profile){ FactoryGirl.create(:employer_profile) }

  let(:employee_role_params){
    {
      employer_profile_id: employer_profile.id,
      census_employee_id: census_employee.id,
      hired_on: 20.days.ago
    }
  }

  let(:person_params) {
    {
      ssn: "444555999",
      first_name: "John",
      last_name: "Doe",
      dob: 20.years.ago,
      gender: "male"
    }
  }

  context "update person contact information from census employee" do
    it "should update the person addresses and email objects." do
      e_role = EmployeeRole.new(**employee_role_params)
      person = Person.create(**person_params)
      person.employee_roles = [e_role]
      person.save
      subject.migrate
      person.reload
      expect(person.addresses).to eq [census_employee.address]
      expect(person.emails.first).to eq census_employee.email
      expect(person.emails.size).to eq 2
    end
  end
end
