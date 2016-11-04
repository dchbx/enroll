require 'rails_helper'

describe EmployeeRole do
  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 6, 20))
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context "an organization exists" do
    let!(:organization) { FactoryGirl.create(:organization) }

    context "with an employer profile" do
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }

      context "and two draft plan years exist" do
        let!(:plan_year_a) { FactoryGirl.create(:plan_year_not_started, employer_profile: employer_profile) }
        let!(:plan_year_b) { FactoryGirl.create(:plan_year_not_started, employer_profile: employer_profile) }

        context "with benefit groups" do
          let!(:benefit_group_a) { FactoryGirl.create(:benefit_group, plan_year: plan_year_a) }
          let!(:benefit_group_b) { FactoryGirl.create(:benefit_group, plan_year: plan_year_b) }

          it "the reference plans should not be the same" do
            expect(benefit_group_a.reference_plan_id).not_to eq benefit_group_b.reference_plan_id
          end

          context "and we have an employee on the roster" do
            let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

            context "and a new employee role is created" do
              let(:employee_role) do
                Factories::EnrollmentFactory.add_employee_role(employer_profile: employer_profile,
                      first_name: census_employee.first_name, last_name: census_employee.last_name,
                      ssn: census_employee.ssn, dob: census_employee.dob, gender: census_employee.gender, hired_on: census_employee.hired_on)[0]
              end

              context "and the employee is assigned to both benefit groups" do
                let!(:benefit_group_assignment_a) { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group_a) }
                let!(:benefit_group_assignment_b) { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group_b) }

                context "and the first plan year is published" do
                  before do
                    plan_year_a.publish!
                  end

                  it "that plan year should be published" do
                    expect(plan_year_a.aasm_state).to eq "published"
                  end

                  it "the new employee role should see the correct benefit group" do
                    expect(employee_role.benefit_group.id).to eq benefit_group_a.id
                  end
                end

                context "and the other plan year is published" do
                  before do
                    plan_year_b.publish!
                  end

                  it "that plan year should be published" do

                    expect(plan_year_b.aasm_state).to eq "published"
                  end

                  it "the new employee role should see the correct benefit group" do
                    expect(employee_role.benefit_group.id).to eq benefit_group_b.id
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
