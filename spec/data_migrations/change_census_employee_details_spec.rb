require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_census_employee_details")

describe ChangeCensusEmployeeDetails, dbclean: :after_each do

  let(:given_task_name) { "change_census_employee_details" }
  subject { ChangeCensusEmployeeDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end


  describe "update_terminated_on" do
    let(:census_employee)     { FactoryGirl.create(:census_employee, :employment_terminated_on => TimeKeeper.date_of_record - 1.month)}
    let(:terminated_on)     { TimeKeeper.date_of_record }

    it "should change the terminated_on date" do
      subject.send(:update_terminated_on, census_employee, terminated_on)
      expect(census_employee.employment_terminated_on).to eq(terminated_on)
    end
  end

  describe "update_enrollments" do
    let(:census_employee)     { FactoryGirl.create(:census_employee, :employment_terminated_on => TimeKeeper.date_of_record)}
    let(:terminated_on)     { TimeKeeper.date_of_record }
    let(:benefit_group_assignment)    { FactoryGirl.build(:benefit_group_assignment) }
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}

    let(:hbx_enrollment)    { FactoryGirl.build(:hbx_enrollment, :household => family.active_household, :aasm_state => "coverage_terminated", :terminated_on => TimeKeeper.date_of_record - 1.month) }

    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    end

    it "should change the terminated_on date" do
      subject.send(:update_enrollments, census_employee, terminated_on)
      expect(census_employee.coverage_terminated_on).to eq(terminated_on)
      expect(hbx_enrollment.terminated_on).to eq(terminated_on)
    end
  end

  describe "census_employee" do
    let(:employer_profile)     { FactoryGirl.create(:employer_profile) }
    let(:census_employee)     { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }

    it "should return the census employee" do
      found_employee = subject.send(:census_employee, census_employee.ssn, employer_profile.fein)
      expect(found_employee).to eq(census_employee)
    end

    context "census employee not found" do
      it "should return the census employee" do
        expect { subject.send(:census_employee, "000000000", employer_profile.fein) }.to raise_error("Census_employee not found SSN 000000000 Employer FEIN #{employer_profile.fein}")
      end
    end
  end

  describe "change_ssn" do
    let(:census_employee) { FactoryGirl.create :census_employee}

    before :each do
      allow(ENV).to receive(:[]).with("encrypted_ssn").and_return census_employee.encrypted_ssn
      allow(ENV).to receive(:[]).with("new_encrypted_ssn").and_return SymmetricEncryption.encrypt("123111222")
    end

    it "should change the SSN of census employee if in eligible status" do
      subject.send(:change_ssn)
      census_employee.reload
      expect(census_employee.ssn).to eq "123111222"
    end

    it "should not change the SSN of census employee if in linked status" do
      ssn = census_employee.ssn
      census_employee.reload
      census_employee.update_attributes(aasm_state: "employee_role_linked")
      subject.send(:change_ssn)
      expect(census_employee.ssn).to eq ssn
    end
  end

  describe "delink_employee_role" do
    let(:census_employee) { FactoryGirl.create :census_employee}
    let(:employee_role) { FactoryGirl.create :employee_role}

    before :each do
      allow(ENV).to receive(:[]).with("encrypted_ssn").and_return census_employee.encrypted_ssn
      census_employee.update_attributes(aasm_state: "employee_role_linked", employee_role_id: employee_role.id)
    end

    it "should delink the employee role" do
      subject.send(:delink_employee_role)
      census_employee.reload
      expect(census_employee.employee_role_id).to eq nil
      expect(census_employee.aasm_state).to eq "eligible"
    end
  end

  describe "link_or_construct_employee_role" do
    let!(:person) { FactoryGirl.create(:person, 
      first_name: census_employee.first_name,
      last_name: census_employee.last_name,
      dob: census_employee.dob,
      ssn: census_employee.ssn
    )}
    let(:census_employee) { FactoryGirl.create :census_employee_with_active_assignment}
    let(:benefit_group) { FactoryGirl.create :benefit_group}
    let(:employer_profile) { FactoryGirl.create :employer_profile}

    before :each do
      allow(ENV).to receive(:[]).with("encrypted_ssn").and_return census_employee.encrypted_ssn
      allow(census_employee).to receive(:has_benefit_group_assignment?).and_return true
      census_employee.active_benefit_group_assignment.update_attributes(benefit_group_id: benefit_group.id)
      benefit_group.plan_year.update_attributes(aasm_state: "active")
      census_employee.update_attributes(:employer_profile_id => employer_profile.id, aasm_state: "eligible")
    end

    it "should construct the employee role" do
      expect(census_employee.employee_role).to eq nil
      subject.send(:link_or_construct_employee_role)
      census_employee.reload
      expect(census_employee.employee_role).not_to eq nil
    end

    it "should link the employee role" do
      subject.send(:link_or_construct_employee_role)
      census_employee.reload
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end
  end

  before :each do
    CensusEmployee.skip_callback(:save, :after, :assign_default_benefit_package)
  end

  after :each do
    CensusEmployee.set_callback(:save, :after, :assign_default_benefit_package)
  end
end
