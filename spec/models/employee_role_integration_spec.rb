require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe EmployeeRole, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application" do
    let(:aasm_state) { :draft }
  end

  let(:person) {FactoryBot.create(:person, :with_family)}

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 6, 20))
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context "employer with two draft plan years exist" do
    let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
    let(:plan_year_a) { FactoryBot.create(:benefit_sponsors_benefit_application,
                                          :with_benefit_package,
                                          :benefit_sponsorship => benefit_sponsorship,
                                          :aasm_state => 'draft',
                                          :effective_period =>  start_on..(start_on + 1.year) - 1.day
    )}
    let(:plan_year_b) { initial_application }

    context "with benefit groups" do
      let(:benefit_group_a)    { plan_year_a.benefit_packages.first }
      let(:benefit_group_b)    { plan_year_b.benefit_packages.first }

      context "and we have an employee on the roster" do
        let(:census_employee) { FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }

        context "and a new employee role is created" do
          let(:employee_role) {FactoryBot.create(:employee_role, person: person, census_employee_id: census_employee.id, employer_profile: abc_profile)}

          context "and the employee is assigned to both benefit groups" do
            let(:benefit_group_assignment_a) { FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group_a) }
            let(:benefit_group_assignment_b) { FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group_b) }

            context "and the first plan year is published" do
              before do
                plan_year_a.approve_application!
              end

              it "that plan year should be published" do
                expect(plan_year_a.aasm_state).to eq :approved
              end

              it "the new employee role should see the correct benefit group" do
                allow(census_employee).to receive(:under_new_hire_enrollment_period?).and_return(false)
                expect(employee_role.benefit_group.id).to eq benefit_group_a.id
              end
            end

            context "and the other plan year is published" do
              before do
                plan_year_b.approve_application!
              end

              it "that plan year should be published" do

                expect(plan_year_b.aasm_state).to eq :approved
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
