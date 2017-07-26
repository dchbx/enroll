require 'rails_helper'

RSpec.describe CensusEmployeeImport, :type => :model do

  let(:tempfile) { double("", path: 'spec/test_data/census_employee_import/DCHL Employee Census.xlsx') }
  let(:file) {
    double("", :tempfile => tempfile)
  }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:sheet) {
    Roo::Spreadsheet.open(file.tempfile.path).sheet(0)
  }
  let(:subject) {
    CensusEmployeeImport.new({file: file, employer_profile: employer_profile})
  }

  context "initialize without employer_role and file" do
    it "throws exception" do
      expect { CensusEmployeeImport.new() }.to raise_error(ArgumentError)
    end
  end

  context "initialize with employer_role and file" do
    it "should not throw an exception" do
      expect { CensusEmployeeImport.new({file: file, employer_profile: employer_profile}) }.to_not raise_error
    end
  end

  it "should validate headers" do
    sheet_header_row = sheet.row(1)
    column_header_row = sheet.row(2)
    expect(subject.header_valid?(sheet_header_row) && subject.column_header_valid?(column_header_row)).to be_truthy
  end

  context "One employee with one dependent" do
    it "should added a employee with a dependent" do
      expect(subject.save).to be_truthy
      expect(subject.load_imported_census_employees.count).to eq(2) # 1 employee + 1 dependent
      expect(subject.load_imported_census_employees.first).to be_a CensusEmployee
      expect(subject.load_imported_census_employees.first.census_dependents.count).to eq(1)
      expect(subject.load_imported_census_employees.last).to be_a CensusDependent
    end

    it "should save the employee with address_kind_even_without_input_address_kind" do
      expect(subject.save).to be_truthy
      expect(subject.load_imported_census_employees.first.address.kind).to eq 'home'
      expect(subject.load_imported_census_employees.first.address.present?).to be_truthy
      expect(subject.load_imported_census_employees.first.address.address_2.present?).to be_truthy
    end

    it "should save the employee & dependent with correct attributes" do
      expect(subject.save).to be_truthy
      expect(subject.load_imported_census_employees.first.first_name).to eq "test"
      expect(subject.load_imported_census_employees.first.last_name).to eq "test"
      expect(subject.load_imported_census_employees.first.gender).to eq "male"
      expect(subject.load_imported_census_employees.first.census_dependents.first.first_name).to eq "test2"
      expect(subject.load_imported_census_employees.first.census_dependents.first.last_name).to eq "test2"
      expect(subject.load_imported_census_employees.first.census_dependents.first.employee_relationship).to eq "spouse"
      expect(subject.load_imported_census_employees.first.census_dependents.first.gender).to eq "female"
    end

  end

  context "relationship field is empty" do

    let(:tempfile) { double("", path: 'spec/test_data/census_employee_import/DCHL Employee Census 2.xlsx') }
    let(:file) {
      double("", :tempfile => tempfile)
    }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:sheet) {
      Roo::Spreadsheet.open(file.tempfile.path).sheet(0)
    }
    let(:subject) {
      CensusEmployeeImport.new({file: file, employer_profile: employer_profile})
    }

    it "should not add the 2nd employee/dependent (as relationship is missing)" do
      expect(subject.save).to be_falsey
      expect(subject.load_imported_census_employees.count).to eq(1) # 1 employee + no dependents
      expect(subject.load_imported_census_employees.first).to be_a CensusEmployee
      expect(subject.load_imported_census_employees.first.census_dependents.count).to eq(0)
      expect(subject.load_imported_census_employees.first.last_name).to eq "panther1"
    end

    it "should not save successfully" do
      expect(subject.save).to be_falsey
    end
  end

  context "terminate employee" do
    let(:tempfile) { double("", path: 'spec/test_data/census_employee_import/DCHL Employee Census 3.xlsx') }
    let(:file) { double("", :tempfile => tempfile) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:census_employee) { FactoryGirl.create(:census_employee, {ssn: "111111111", dob: Date.new(1987, 12, 12), employer_profile: employer_profile}) }

    context "employee does not exist" do
      it "should fail" do
        expect(subject.save).to be_falsey
        expect(subject.errors.messages[:base]).to include("Row 4: Employee/Dependent not found or not active")
        expect(subject.instance_variable_get("@terminate_queue").length).to eq(0)
      end
    end

    context "employee exists" do
      before do
        allow(subject).to receive(:find_employee).and_return(census_employee)
        allow(subject).to receive(:is_employee_terminable?).with(census_employee).and_return(true)
      end

      it "should save successfully" do
        expect(subject.save).to be_truthy
        expect(subject.load_imported_census_employees.count).to eq(1)
        expect(subject.instance_variable_get("@terminate_queue").length).to eq(1)
      end
    end
  end

  context "#assign_census_employee_attributes" do
    let(:member) { CensusEmployee.new}
    let(:record) {
      {
        employer_assigned_family_id: nil,
        first_name: "Mike",
        last_name: "Scofield",
        ssn: "789765567",
        dob: TimeKeeper.date_of_record - 30.years,
        hire_date: TimeKeeper.date_of_record - 1.year,
        is_business_owner: "no",
        gender: "male",
        employee_relationship: "Employee",
        email: nil
      }
    }

    context "it should assign the census employee attributes on the object" do

      before do
        @result = subject.assign_census_employee_attributes(member, record)
      end

      it "should return census employee" do
        expect(@result.class).to eq CensusEmployee
      end

      shared_examples_for "assign_census_employee_attributes" do |attr_key, value|
        it "should assign #{attr_key}" do
          expect(@result.send(attr_key)).to eq value
        end
      end

      it_behaves_like "assign_census_employee_attributes", "employer_assigned_family_id", nil
      it_behaves_like "assign_census_employee_attributes", "first_name", "Mike"
      it_behaves_like "assign_census_employee_attributes", "last_name", "Scofield"
      it_behaves_like "assign_census_employee_attributes", "ssn", "789765567"
      it_behaves_like "assign_census_employee_attributes", "dob", TimeKeeper.date_of_record - 30.years
      it_behaves_like "assign_census_employee_attributes", "hired_on", TimeKeeper.date_of_record - 1.year
      it_behaves_like "assign_census_employee_attributes", "is_business_owner", false
      it_behaves_like "assign_census_employee_attributes", "gender", "male"
      it_behaves_like "assign_census_employee_attributes", "employee_relationship", "employee"
      it_behaves_like "assign_census_employee_attributes", "email", nil

    end

    context "is_business_owner", dbclean: :after_each do

      shared_examples_for "is_business_owner" do |input, value|
        let(:record) {
          {
            :is_business_owner => subject.parse_boolean(input)
          }
        }

        it "it should return #{value} when received #{input} in is_business_owner field" do
          result = subject.assign_census_employee_attributes(member, record)
          expect(result.is_business_owner).to eq value
        end
      end

      it_behaves_like "is_business_owner", nil, false
      it_behaves_like "is_business_owner", "yes", true
      it_behaves_like "is_business_owner", "no", false
      it_behaves_like "is_business_owner", "true", true
      it_behaves_like "is_business_owner", "false", false
    end
  end
end
