require "rails_helper"

describe Importers::ConversionEmployeeAction, :dbclean => :after_each do
  context "where the sponsor employer is not found" do
    let(:bogus_employer_fein) { "000093939" }
    subject { Importers::ConversionEmployeeAction.new(:fein => bogus_employer_fein) }

    before(:each) do
      allow(Organization).to receive(:where).with({:fein => bogus_employer_fein}).and_return([])
      subject.valid?
    end

    it "adds an 'employer not found' error to the instance" do
      expect(subject.errors.get(:fein)).to include("does not exist")
    end
  end

  context "where the sponsor employer is found" do

    let(:employer_profile) { FactoryGirl.create(:employer_profile, profile_source: 'conversion') }

    let(:carrier_profile) { FactoryGirl.create(:carrier_profile) }

    let(:renewal_health_plan)   {
      FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2016, carrier_profile_id: carrier_profile.id)
    }

    let(:current_health_plan)   {
      FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2015, renewal_plan_id: renewal_health_plan.id, carrier_profile_id: carrier_profile.id)
    }

    let(:plan_year)            {
      py = FactoryGirl.create(:plan_year,
                              start_on: Date.new(2015, 7, 1),
                              end_on: Date.new(2016, 6, 30),
                              open_enrollment_start_on: Date.new(2015, 6, 1),
                              open_enrollment_end_on: Date.new(2015, 6, 10),
                              employer_profile: employer_profile
                             )

      py.benefit_groups = [
        FactoryGirl.build(:benefit_group,
                          title: "blue collar",
                          plan_year: py,
                          reference_plan_id: current_health_plan.id,
                          elected_plans: [current_health_plan]
                         )
      ]
      py.save(:validate => false)
      py.update_attributes({:aasm_state => 'active'})
      py
    }

    let(:employer_fein) { 
      employer_profile.fein
    } 

    context "and a pre-existing employee record is not found" do
      let(:conversion_employee_props) do
        {
          :fein => employer_fein,
          :subscriber_ssn => census_employee.ssn,
          :subscriber_dob => census_employee.dob
        } 
      end

      let(:census_employee) {
        FactoryGirl.build(:census_employee, :employer_profile => employer_profile)
      }

      let(:subject) { ::Importers::ConversionEmployeeAction.new(conversion_employee_props) }

      let(:mock_create) { double(:save => true, :warnings => [], :errors => [])}

      it "adds the employee record" do
        expect(::Importers::ConversionEmployeeCreate).to receive(:new).with(conversion_employee_props).and_return(mock_create)
        expect(subject.save).to be_truthy
      end
    end

    context "and a pre-existing employee record is found" do
      let(:conversion_employee_props) do
        {
          :fein => employer_fein,
          :subscriber_ssn => census_employee.ssn,
          :subscriber_dob => census_employee.dob,
          :hire_date => census_employee.hired_on.strftime("%m/%d/%Y")
        } 
      end

      let(:census_employee) {
        FactoryGirl.create(:census_employee, :employer_profile => employer_profile)
      }

      let(:mock_update) { double(:save => true, :warnings => [], :errors => [])}

      let(:subject) { ::Importers::ConversionEmployeeAction.new(conversion_employee_props) }

      it "updates the employee record" do
        expect(::Importers::ConversionEmployeeUpdate).to receive(:new).with(conversion_employee_props).and_return(mock_update)
        expect(subject.save).to be_truthy
      end
    end
  end
end
