require 'rails_helper'

RSpec.describe SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport, type: :model, dbclean: :after_each do

  let(:tempfile) { double("", path: 'spec/test_data/census_employee_import/DCHL Employee Census.xlsx') }
  let(:file) { double("", :tempfile => tempfile) }

  let(:broker_agency_profile_id) { "216735" }
  let!(:organization) { create(:sponsored_benefits_plan_design_organization, :with_profile, sic_code: '0197') }
  let(:plan_design_proposal) { organization.plan_design_proposals[0] }
  let(:employer_profile) { plan_design_proposal.profile }
  let(:benefit_sponsorship) { employer_profile.benefit_sponsorships[0] }

  let(:sheet) { Roo::Spreadsheet.open(file.tempfile.path).sheet(0) }
  let(:subject) { SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new({file: file, employer_profile: employer_profile}) }

  before do
    subject.proposal = plan_design_proposal
  end

  context "initialize without employer_role and file" do
    it "throws exception" do
      expect { SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new() }.to raise_error(ArgumentError)
    end
  end

  context "initialize with employer_role and file" do
    it "should not throw an exception" do
      expect { SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new({file: file, employer_profile: employer_profile}) }.to_not raise_error
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
      expect(subject.load_imported_census_employees.first).to be_a SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
      expect(subject.load_imported_census_employees.first.census_dependents.count).to eq(1)
      expect(subject.load_imported_census_employees.last).to be_a SponsoredBenefits::CensusMembers::CensusDependent
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
    let(:subject) {
      SponsoredBenefits::Forms::PlanDesignCensusEmployeeImport.new({file: file, employer_profile: employer_profile})
    }

    it "should not add the 2nd employee/dependent (as relationship is missing)" do
      expect(subject.save).to be_falsey
      expect(subject.load_imported_census_employees.count).to eq(1) # 1 employee + no dependents
      expect(subject.load_imported_census_employees.first).to be_a SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
      expect(subject.load_imported_census_employees.first.census_dependents.count).to eq(0)
      expect(subject.load_imported_census_employees.first.last_name).to eq "panther1"
    end

    it "should not save successfully" do
      expect(subject.save).to be_falsey
    end
  end

  context "terminate employee" do
    let(:tempfile) { double("", path: 'spec/test_data/census_employee_import/DCHL Employee Census 3.xlsx') }

    context "employee does not exist" do
      it "should load none" do
        expect(subject.imported_census_employees.compact.empty?).to be_truthy
      end
    end

    context "employee exists" do
      let(:census_employee) { FactoryGirl.create(:plan_design_census_employee, {ssn: "111111111", dob: Date.new(1987, 12, 12), benefit_sponsorship: benefit_sponsorship}) }

      before do
        allow(subject).to receive(:find_employee).and_return(census_employee)
        allow(subject).to receive(:is_employee_terminable?).with(census_employee).and_return(true)
      end

      it "should save successfully" do
        expect(subject.save).to be_truthy
        expect(subject.load_imported_census_employees.count).to eq(1)
      end
    end

  end
end
