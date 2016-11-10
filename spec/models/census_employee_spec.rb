require 'rails_helper'

RSpec.describe CensusEmployee, type: :model, dbclean: :after_each do
  # it { should validate_presence_of :ssn }
  # it { should validate_presence_of :dob }
  # it { should validate_presence_of :hired_on }
  # it { should validate_presence_of :is_business_owner }
  # it { should validate_presence_of :employer_profile_id }

  let(:benefit_group)    { plan_year.benefit_groups.first }
  let(:plan_year)        do
    py = FactoryGirl.create(:plan_year_not_started)
    bg = FactoryGirl.create(:benefit_group, plan_year: py)
    PlanYear.find(py.id)
  end
  let(:employer_profile) { plan_year.employer_profile }

  let(:first_name){ "Lynyrd" }
  let(:middle_name){ "Rattlesnake" }
  let(:last_name){ "Skynyrd" }
  let(:name_sfx){ "PhD" }
  let(:ssn){ "230987654" }
  let(:dob){ TimeKeeper.date_of_record - 31.years }
  let(:gender){ "male" }
  let(:hired_on){ TimeKeeper.date_of_record - 14.days }
  let(:is_business_owner){ false }
  let(:address) { Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001") }
  let(:autocomplete) { " lynyrd skynyrd" }

  let(:valid_params){
    {
      employer_profile: employer_profile,
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      name_sfx: name_sfx,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hired_on: hired_on,
      is_business_owner: is_business_owner,
      address: address
    }
  }

  context "a new instance" do
    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(CensusEmployee.create(**params).valid?).to be_falsey
      end
    end

    context "with no employer_profile" do
      let(:params) {valid_params.except(:employer_profile)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:employer_profile_id].any?).to be_truthy
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:ssn].any?).to be_truthy
      end
    end

    context "with no dob" do
      let(:params) {valid_params.except(:dob)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:dob].any?).to be_truthy
      end
    end

    context "with no hired_on" do
      let(:params) {valid_params.except(:hired_on)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:hired_on].any?).to be_truthy
      end
    end

    context "with no is owner" do
      let(:params) { valid_params.merge({:is_business_owner => nil}) }

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_business_owner].any?).to be_truthy
      end
    end

    context "with all required attributes" do
      let(:params)                  { valid_params }
      let(:initial_census_employee) { CensusEmployee.new(**params) }
      let(:dependent) { CensusDependent.new(first_name:'David', last_name:'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male") }
      let(:dependent2) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333333333, dob: TimeKeeper.date_of_record - 30.years, gender: "male") }

      it "should be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end

      it "should save" do
        expect(initial_census_employee.save).to be_truthy
      end
      
      it "allow dependent ssn's to be updated to nil" do
        initial_census_employee.census_dependents = [dependent]
        initial_census_employee.save!
        expect(initial_census_employee.census_dependents.first.ssn).to match(nil)
      end
      
      it "ignores depepent ssn's if ssn not nil" do
        initial_census_employee.census_dependents = [dependent2]
        initial_census_employee.save!
        expect(initial_census_employee.census_dependents.first.ssn).to match("333333333")
      end

      context "with duplicate ssn's on dependents" do
        let(:child1) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333333333) }
        let(:child2) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333333333) }

        it "should have errors" do
          initial_census_employee.census_dependents = [child1,child2]
          expect(initial_census_employee.save).to be_falsey
          expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
        end
      end
      
      context "with duplicate blank ssn's on dependents" do
        let(:child1) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: "") }
        let(:child2) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: "") }
        
        it "should not have errors" do
          initial_census_employee.census_dependents = [child1,child2]
          expect(initial_census_employee.valid?).to be_truthy
        end
      end

      context "with ssn matching subscribers" do
        let(:child1) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: initial_census_employee.ssn) }

        it "should have errors" do
          initial_census_employee.census_dependents = [child1]
          expect(initial_census_employee.save).to be_falsey
          expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
        end
      end
      
      context "and it is saved" do
        before { initial_census_employee.save }

        it "should be findable by ID" do
          expect(CensusEmployee.find(initial_census_employee.id)).to eq initial_census_employee
        end

        # it "should have a valid autocomplete" do
        #   expect(initial_census_employee.autocomplete).to eq autocomplete
        # end

        it "in an unlinked state" do
          expect(initial_census_employee.eligible?).to be_truthy
        end

        it "and should have the correct associated employer profile" do
          expect(initial_census_employee.employer_profile._id).to eq initial_census_employee.employer_profile_id
        end

        it "should be findable by employer profile" do
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).size).to eq 1
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).first).to eq initial_census_employee
        end

        context "and a benefit group isn't yet assigned to employee" do
          it "the roster instance should not be ready for linking" do
            expect(initial_census_employee.may_link_employee_role?).to be_falsey
          end

          context "and census employee identifying info is edited" do
            before { initial_census_employee.ssn = "606060606" }

            it "should be be valid" do
              expect(initial_census_employee.valid?).to be_truthy
            end
          end

          context "and the employee is assigned a benefit group" do
            let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee) }

            before do
              initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
              initial_census_employee.save
            end

            context "and the benefit group plan year isn't published" do
              it "the roster instance should not be ready for linking" do
                expect(initial_census_employee.may_link_employee_role?).to be_falsey
              end
            end

            context "and the benefit group plan year is published" do
              before { plan_year.publish! }

              it "the employee census record should be ready for linking" do
                expect(initial_census_employee.may_link_employee_role?).to be_truthy
              end

              context "and a roster match by SSN and DOB is performed" do
                context "using non-matching ssn and dob" do
                  let(:invalid_employee_role)   { FactoryGirl.create(:employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days) }

                  it "should return an empty array" do
                    expect(CensusEmployee.matchable(invalid_employee_role.ssn, invalid_employee_role.dob)).to eq []
                  end
                end

                context "using matching ssn and dob" do
                  let(:valid_employee_role)     { FactoryGirl.create(:employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile) }

                  it "should return the roster instance" do
                    expect(CensusEmployee.matchable(valid_employee_role.ssn, valid_employee_role.dob).collect(&:id)).to eq [initial_census_employee.id]
                  end

                  context "and a link employee role request is received" do
                    context "and the provided employee role identifying information doesn't match a census employee" do
                      let(:invalid_employee_role)   { FactoryGirl.create(:employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days) }

                      it "should raise an error" do
                        initial_census_employee.employee_role = invalid_employee_role
                        expect(initial_census_employee.employee_role_linked?).to be_falsey
                      end
                    end

                    context "and the provided employee role identifying information does match a census employee" do
                      before { initial_census_employee.employee_role = valid_employee_role }

                      it "should link the roster instance and employer role" do
                        expect(initial_census_employee.employee_role_linked?).to be_truthy
                      end

                      context "and it is saved" do
                        before { initial_census_employee.save }

                        it "should no longer be available for linking" do
                          expect(initial_census_employee.may_link_employee_role?).to be_falsey
                        end

                        it "should be findable by employee role" do
                          expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).size).to eq 1
                          expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).first).to eq initial_census_employee
                        end

                        it "and should be delinkable" do
                          expect(initial_census_employee.may_delink_employee_role?).to be_truthy
                        end

                        it "should have a published benefit group" do
                          expect(initial_census_employee.published_benefit_group).to eq benefit_group
                        end

                        context "and census employee identifying info is edited" do
                          before { initial_census_employee.ssn = "606060606" }

                          it "should be invalid" do
                            expect(initial_census_employee.valid?).to be_falsey
                            expect(initial_census_employee.errors[:base].first).to match(/An employee's identifying information may change only when/)
                          end

                        end

                        context "and employee is terminated and reported by employer on timely basis" do
                          let(:earliest_retro_coverage_termination_date)    { (TimeKeeper.date_of_record.advance(
                                                                                  Settings.
                                                                                  aca.
                                                                                  shop_market.
                                                                                  retroactive_coverage_termination_maximum.
                                                                                  to_hash)
                                                                                ).end_of_month
                                                                              }
                          let(:earliest_valid_employment_termination_date)  { earliest_retro_coverage_termination_date.beginning_of_month }
                          let(:invalid_employment_termination_date) { earliest_valid_employment_termination_date - 1.day }
                          let(:invalid_coverage_termination_date)   { invalid_employment_termination_date.end_of_month }


                          context "and the employment termination is reported later after max retroactive date" do

                            before { initial_census_employee.terminate_employment!(invalid_employment_termination_date) }

                            it "calculated coverage termination date should preceed the valid coverage termination date" do
                              expect(invalid_coverage_termination_date).to be < earliest_retro_coverage_termination_date
                            end

                            it "is in terminated state" do
                              expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
                            end

                            it "should have the correct employment termination date" do
                              expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq invalid_employment_termination_date
                            end

                            it "should have the earliest coverage termination date" do
                              expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
                            end

                            context "and the user is HBX admin" do
                              it "should use cancancan to permit admin termination"
                            end
                          end

                          context "and the termination date is in the future" do
                              before { initial_census_employee.terminate_employment!(TimeKeeper.date_of_record + 10.days) }
                              it "is in termination pending state" do
                                expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
                              end
                          end

                          context "and the termination date is within the retroactive reporting time period" do
                            before { initial_census_employee.terminate_employment!(earliest_valid_employment_termination_date) }

                            it "is in terminated state" do
                              expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
                            end

                            it "should have the correct employment termination date" do
                              expect(CensusEmployee.find(initial_census_employee.id).employment_terminated_on).to eq earliest_valid_employment_termination_date
                            end

                            it "should have the earliest coverage termination date" do
                              expect(CensusEmployee.find(initial_census_employee.id).coverage_terminated_on).to eq earliest_retro_coverage_termination_date
                            end


                            context "and the terminated employee is rehired" do
                              let!(:rehire)   { initial_census_employee.replicate_for_rehire }

                              it "rehired census employee instance should have same demographic info" do
                                expect(rehire.first_name).to eq initial_census_employee.first_name
                                expect(rehire.last_name).to eq initial_census_employee.last_name
                                expect(rehire.gender).to eq initial_census_employee.gender
                                expect(rehire.ssn).to eq initial_census_employee.ssn
                                expect(rehire.dob).to eq initial_census_employee.dob
                                expect(rehire.employer_profile).to eq initial_census_employee.employer_profile
                              end

                              it "rehired census employee instance should be initialized state" do
                                expect(rehire.eligible?).to be_truthy
                                expect(rehire.hired_on).to_not eq initial_census_employee.hired_on
                                expect(rehire.active_benefit_group_assignment.present?).to be_falsey
                                expect(rehire.employee_role.present?).to be_falsey
                              end

                              it "the previously terminated census employee should be in rehired state" do
                                expect(initial_census_employee.aasm_state).to eq "rehired"
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
          end

          context "and employer is renewing" do
          end

        end
      end
    end

    context "multiple employers have active, terminated and rehired employees", dbclean: :around_each do
      let(:today)                          { TimeKeeper.date_of_record }
      let(:one_month_ago)                  { today - 1.month }
      let(:last_month)                     { one_month_ago.beginning_of_month..one_month_ago.end_of_month}
      let(:last_year_to_date)              { (today - 1.year)..today }

      let(:er1_active_employee_count)      { 2 }
      let(:er1_terminated_employee_count)  { 1 }
      let(:er1_rehired_employee_count)     { 1 }

      let(:er2_active_employee_count)      { 1 }
      let(:er2_terminated_employee_count)  { 1 }

      let(:employee_count)                 {
                                              er1_active_employee_count +
                                              er1_terminated_employee_count +
                                              er1_rehired_employee_count +
                                              er2_active_employee_count +
                                              er2_terminated_employee_count
                                           }

      let(:terminated_today_employee_count)       { 2 }
      let(:terminated_last_month_employee_count)  { 1 }
      let(:er1_termination_count)                 { er1_terminated_employee_count + er1_rehired_employee_count }

      let(:terminated_employee_count)      { er1_terminated_employee_count + er2_terminated_employee_count }
      let(:termed_status_employee_count)   { terminated_employee_count + er1_rehired_employee_count }

      let(:employer_count)                 { 2 }
      let(:employer_profile_1)             { FactoryGirl.create(:employer_profile) }
      let(:employer_profile_2)             { FactoryGirl.create(:employer_profile) }

      let(:er1_active_employees)      { FactoryGirl.create_list(:census_employee, er1_active_employee_count,
                                                                 employer_profile: employer_profile_1
                                                                )
                                                              }
      let(:er1_terminated_employees)  { FactoryGirl.create_list(:census_employee, er1_terminated_employee_count,
                                                                 employer_profile: employer_profile_1
                                                                )
                                                              }
      let(:er1_rehired_employees)     { FactoryGirl.create_list(:census_employee, er1_rehired_employee_count,
                                                                 employer_profile: employer_profile_1
                                                            )
                                                          }
      let(:er2_active_employees)      { FactoryGirl.create_list(:census_employee, er2_active_employee_count,
                                                                 employer_profile: employer_profile_2
                                                                )
                                                              }
      let(:er2_terminated_employees)  { FactoryGirl.create_list(:census_employee, er2_terminated_employee_count,
                                                                 employer_profile: employer_profile_2
                                                                )
                                                              }

      before do
        er1_active_employees.each do |ee|
          ee.aasm_state = "employee_role_linked"
          ee.save!
        end

        er1_terminated_employees.each do |ee|
          ee.aasm_state = "employment_terminated"
          ee.employment_terminated_on = today
          ee.save!
        end

        er1_rehired_employees.each do |ee|
          ee.aasm_state = "rehired"
          ee.employment_terminated_on = today
          ee.save!
        end

        er2_active_employees.each do |ee|
          ee.aasm_state = "employee_role_linked"
          ee.save!
        end

        er2_terminated_employees.each do |ee|
          ee.aasm_state = "employment_terminated"
          ee.employment_terminated_on = one_month_ago
          ee.save!
        end
      end

      it "should find all employers" do
        expect(EmployerProfile.all.size).to eq employer_count
      end

      it "should find all employees" do
        expect(CensusEmployee.all.size).to eq employee_count
      end

      context "and terminated employees are queried with no passed parameters" do
        it "should find the all employees terminated today" do
          expect(CensusEmployee.find_all_terminated.size).to eq terminated_today_employee_count
        end
      end

      context "and terminated employees who were terminated one month ago are queried" do
        it "should find the correct set" do
          expect(CensusEmployee.find_all_terminated(date_range: last_month).size).to eq terminated_last_month_employee_count
        end
      end

      context "and for one employer, the set of employees terminated since company joined the exchange are queried" do
        it "should find the correct set" do
          expect(CensusEmployee.find_all_terminated(employer_profiles: [employer_profile_1],
                                                    date_range: last_year_to_date).size).to eq er1_termination_count
        end
      end

    end

    context "a census employee is added in the database" do
      let!(:existing_census_employee)     { CensusEmployee.create(
                                              first_name: "Paxton",
                                              last_name: "Thomas",
                                              ssn: "551345151",
                                              dob: "2014-04-01".to_date,
                                              gender: "male",
                                              employer_profile: employer_profile,
                                              hired_on: "2014-08-12".to_date
                                            )}
      let!(:person)                       { Person.create(
                                              first_name: existing_census_employee.first_name,
                                              last_name: existing_census_employee.last_name,
                                              ssn: existing_census_employee.ssn,
                                              dob: existing_census_employee.dob,
                                              gender: existing_census_employee.gender
                                            )}
      let!(:employee_role)                { EmployeeRole.create(
                                              person: person,
                                              hired_on: existing_census_employee.hired_on,
                                              employer_profile: existing_census_employee.employer_profile,
                                            )}

      it "existing record should be findable" do
        expect(CensusEmployee.find(existing_census_employee.id)).to be_truthy
      end

      context "and a new census employee instance, with same ssn same employer profile is built" do
        let!(:duplicate_census_employee)    { existing_census_employee.dup }

        it "should have same identifying info" do
          expect(duplicate_census_employee.ssn).to eq existing_census_employee.ssn
          expect(duplicate_census_employee.employer_profile_id).to eq existing_census_employee.employer_profile_id
        end

        context "and existing census employee is in eligible status" do
          it "existing record should be eligible status" do
            expect(CensusEmployee.find(existing_census_employee.id).aasm_state).to eq "eligible"
          end

          it "new instance should fail validation" do
            expect(duplicate_census_employee.valid?).to be_falsey
            expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
          end

          context "and assign existing census employee to benefit group" do
            let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: existing_census_employee) }

            let!(:saved_census_employee) do
              ee = CensusEmployee.find(existing_census_employee.id)
              ee.benefit_group_assignments = [benefit_group_assignment]
              ee.save
              ee
            end

            context "and publish the plan year and associate census employee with employee_role" do
              before do
                plan_year.publish!
                saved_census_employee.employee_role = employee_role
                saved_census_employee.save
              end

              it "existing census employee should be employee_role_linked status" do
                expect(CensusEmployee.find(saved_census_employee.id).aasm_state).to eq "employee_role_linked"
              end

              it "new cenesus employee instance should fail validation" do
                expect(duplicate_census_employee.valid?).to be_falsey
                expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
              end

              context "and existing employee instance is terminated" do
                before do
                  saved_census_employee.terminate_employment(TimeKeeper.date_of_record-1.day)
                  saved_census_employee.save
                end

                it "should be in terminated state" do
                  expect(saved_census_employee.aasm_state).to eq "employment_terminated"
                end

                it "new instance should save" do
                  expect(duplicate_census_employee.save!).to be_truthy
                end
              end

              context "and the roster census employee instance is in any state besides unlinked" do
                let(:employee_role_linked_state)  { saved_census_employee.dup }
                let(:employment_terminated_state)  { saved_census_employee.dup }
                before do
                  employee_role_linked_state.aasm_state = :employee_role_linked
                  employment_terminated_state.aasm_state = :employment_terminated
                end

                it "should prevent linking with another employee role" do
                  expect(employee_role_linked_state.may_link_employee_role?).to be_falsey
                  expect(employment_terminated_state.may_link_employee_role?).to be_falsey
                end
              end
            end
          end

        end
      end
    end
  end

  context "a plan year application is submitted" do
    before do
      plan_year.open_enrollment_start_on = TimeKeeper.date_of_record + 1.day if plan_year.open_enrollment_start_on = TimeKeeper.date_of_record
      plan_year.publish!
    end

    it "should be in published status" do
      expect(plan_year.aasm_state).to eq "published"
    end
  end

  context "validation for employment_terminated_on" do
    let(:census_employee) {FactoryGirl.build(:census_employee, employer_profile: employer_profile, hired_on: TimeKeeper.date_of_record.beginning_of_year)}

    it "should fail when terminated date before than hired date" do
      census_employee.employment_terminated_on = census_employee.hired_on - 10.days
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:employment_terminated_on].any?).to be_truthy
    end

    it "should fail when terminated date not within 60 days" do
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 75.days
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:employment_terminated_on].any?).to be_truthy
    end

    it "should success" do
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 20.days
      expect(census_employee.valid?).to be_truthy
      expect(census_employee.errors[:employment_terminated_on].any?).to be_falsey
    end
  end

  context "validation for census_dependents_relationship" do
    let(:census_employee) { FactoryGirl.build(:census_employee) }
    let(:spouse1) { FactoryGirl.build(:census_dependent, employee_relationship: "spouse") }
    let(:spouse2) { FactoryGirl.build(:census_dependent, employee_relationship: "spouse") }
    let(:partner1) { FactoryGirl.build(:census_dependent, employee_relationship: "domestic_partner") }
    let(:partner2) { FactoryGirl.build(:census_dependent, employee_relationship: "domestic_partner") }

    it "should fail when have tow spouse" do
      allow(census_employee).to receive(:census_dependents).and_return([spouse1, spouse2])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should fail when have tow domestic_partner" do
      allow(census_employee).to receive(:census_dependents).and_return([partner2, partner1])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should fail when have one spouse and one domestic_partner" do
      allow(census_employee).to receive(:census_dependents).and_return([spouse1, partner1])
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:census_dependents].any?).to be_truthy
    end

    it "should success when have no dependents" do
      allow(census_employee).to receive(:census_dependents).and_return([])
      expect(census_employee.errors[:census_dependents].any?).to be_falsey
    end

    it "should success" do
      allow(census_employee).to receive(:census_dependents).and_return([partner1])
      expect(census_employee.errors[:census_dependents].any?).to be_falsey
    end
  end

  context "scope employee_name" do
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}
    let(:census_employee1) {FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: "Amy", last_name: "Frank")}
    let(:census_employee2) {FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: "Javert", last_name: "Burton")}
    let(:census_employee3) {FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: "Burt", last_name: "Love")}

    before :each do
      CensusEmployee.delete_all
      census_employee1
      census_employee2
      census_employee3
    end

    it "search by first_name" do
      expect(CensusEmployee.employee_name("Javert")).to eq [census_employee2]
    end

    it "search by last_name" do
      expect(CensusEmployee.employee_name("Frank")).to eq [census_employee1]
    end

    it "search by full_name" do
      expect(CensusEmployee.employee_name("Amy Frank")).to eq [census_employee1]
    end

    it "search by part of name" do
      expect(CensusEmployee.employee_name("Bur").count).to eq 2
      expect(CensusEmployee.employee_name("Bur")).to include census_employee2
      expect(CensusEmployee.employee_name("Bur")).to include census_employee3
    end
  end

  context "update_hbx_enrollment_effective_on_by_hired_on" do
    include_context "BradyWorkAfterAll"
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id) }
    let(:person) {double}
    let(:family) {double(active_household: double(hbx_enrollments: double(active: double(open_enrollments: [@enrollment]))))}
    let(:benefit_group) {double}
    before :all do
      create_brady_census_families
      @household = mikes_family.households.first
      @coverage_household = @household.coverage_households.first
      @enrollment = @household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: @coverage_household,
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
      @enrollment.save
    end

    it "should update employee_role hired_on" do
      census_employee.update(hired_on: TimeKeeper.date_of_record + 10.days)
      employee_role.reload
      expect(employee_role.hired_on).to eq TimeKeeper.date_of_record + 10.days
    end

    it "should update hbx_enrollment effective_on" do
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(@enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record - 10.days)
      allow(@enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:effective_on_for).and_return(TimeKeeper.date_of_record + 20.days)

      census_employee.update(hired_on: TimeKeeper.date_of_record + 10.days)
      expect(@enrollment.read_attribute(:effective_on)).to eq TimeKeeper.date_of_record + 20.days
    end
  end


  context "Employee is migrated into Enroll database without an EmployeeRole" do
    let(:person) {}
    let(:family) {}
    let(:employer_profile) {}
    let(:plan_year) {}
    let(:hbx_enrollment) {}
    let(:benefit_group_assignment) {}

    context "and the employee links to roster" do

      it "should create an employee_role"
    end

    context "and the employee is terminated" do

      it "should create an employee_role"
    end
  end

  context "construct_employee_role_for_match_person" do
    let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }
    let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }
    let(:census_employee1) { FactoryGirl.build(:census_employee) }

    it "should return false when not match person" do
      expect(census_employee1.construct_employee_role_for_match_person).to eq false
    end

    it "should return false when match person which has active employee role" do
      expect(census_employee.construct_employee_role_for_match_person).to eq false
    end

    it "should return false when match person which has no active employee role" do
      person.employee_roles.destroy_all
      allow(Factories::EnrollmentFactory).to receive(:build_employee_role).and_return true
      expect(census_employee.construct_employee_role_for_match_person).to eq true
    end
  end

  context "newhire_enrollment_eligible" do
    let(:census_employee) { FactoryGirl.build(:census_employee) }
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment) }
    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end

    it "should return true when active_benefit_group_assignment is initialized" do
      allow(benefit_group_assignment).to receive(:initialized?).and_return true
      expect(census_employee.newhire_enrollment_eligible?).to eq true
    end

    it "should return false when active_benefit_group_assignment is not initialized" do
      allow(benefit_group_assignment).to receive(:initialized?).and_return false
      expect(census_employee.newhire_enrollment_eligible?).to eq false
    end
  end

  context "has_active_health_coverage?" do
    let(:census_employee) { FactoryGirl.create(:census_employee) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:hbx_enrollment) { HbxEnrollment.new(coverage_kind: 'health') }

    it "should return false without benefit_group_assignment" do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return BenefitGroupAssignment.new
      expect(census_employee.has_active_health_coverage?(benefit_group.plan_year)).to be_falsey
    end

    context "with active benefit_group_assignment" do
      before do
        census_employee.add_benefit_group_assignment(benefit_group)
      end

      it "should return false without hbx_enrollment" do
        allow(HbxEnrollment).to receive(:find_shop_and_health_by_benefit_group_assignment).and_return []
        expect(census_employee.has_active_health_coverage?(benefit_group.plan_year)).to be_falsey
      end

      it "should return true when has health hbx_enrollment" do
        allow(HbxEnrollment).to receive(:find_shop_and_health_by_benefit_group_assignment).and_return [hbx_enrollment]
        expect(census_employee.has_active_health_coverage?(benefit_group.plan_year)).to be_truthy
      end
    end
  end

  # context '.edit' do
  #   let(:employee) {FactoryGirl.create(:census_employee, employer_profile: employer_profile)}
  #   let(:user) {FactoryGirl.create(:user)}
  #   let(:hbx_staff) { FactoryGirl.create(:user, :hbx_staff) }
  #   let(:employer_staff) { FactoryGirl.create(:user, :employer_staff) }
  #
  #   context "hbx staff user" do
  #     it "can change dob" do
  #       allow(User).to receive(:current_user).and_return(hbx_staff)
  #       employee.dob = Date.current
  #       expect(employee.save).to be_truthy
  #       allow(User).to receive(:current_user).and_call_original
  #     end
  #
  #     it "can change ssn" do
  #       allow(User).to receive(:current_user).and_return(hbx_staff)
  #       employee.ssn = "123321456"
  #       expect(employee.save).to be_truthy
  #       allow(User).to receive(:current_user).and_call_original
  #     end
  #   end
  #
  #   context "employer staff user" do
  #     before do
  #       allow(User).to receive(:current_user).and_return(employer_staff)
  #     end
  #
  #     after do
  #       allow(User).to receive(:current_user).and_call_original
  #     end
  #
  #     context "not linked" do
  #       before do
  #         allow(employee).to receive(:employee_role_linked?).and_return(false)
  #       end
  #
  #       it "can change dob" do
  #         employee.dob = Date.current
  #         expect(employee.save).to be_truthy
  #       end
  #
  #       it "can change ssn" do
  #         employee.ssn = "123321456"
  #         expect(employee.save).to be_truthy
  #       end
  #     end
  #
  #     context "has linked" do
  #       before do
  #         allow(employee).to receive(:employee_role_linked?).and_return(true)
  #       end
  #
  #       it "can not change dob" do
  #         employee.dob = Date.current
  #         expect(employee.save).to eq false
  #       end
  #       it "can not change ssn" do
  #         employee.ssn = "123321458"
  #         expect(employee.save).to eq false
  #       end
  #     end
  #   end
  #
  #   context "normal user" do
  #     it "can not change dob" do
  #       allow(User).to receive(:current_user).and_return(user)
  #       employee.dob = Date.current
  #       expect(employee.save).to eq false
  #       allow(User).to receive(:current_user).and_call_original
  #     end
  #
  #     it "can not change ssn" do
  #       allow(User).to receive(:current_user).and_return(user)
  #       employee.ssn = "123321458"
  #       expect(employee.save).to eq false
  #       allow(User).to receive(:current_user).and_call_original
  #     end
  #   end
  #
  # end

  context '.new_hire_enrollment_period' do

    let(:census_employee) { CensusEmployee.new(**valid_params) }
    let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    context 'when hired_on date is in the past' do
      it 'should return census employee created date as new hire enrollment period start date' do
        expect(census_employee.new_hire_enrollment_period.min).to eq (census_employee.created_at.beginning_of_day)
      end
    end

    context 'when hired_on date is in the future' do
      let(:hired_on){ TimeKeeper.date_of_record + 14.days }

      it 'should return hired_on date as new hire enrollment period start date' do
        expect(census_employee.new_hire_enrollment_period.min).to eq census_employee.hired_on
      end
    end

    context 'when earliest effective date is in future more than 30 days from current date' do
      let(:hired_on){ TimeKeeper.date_of_record }

      let(:plan_year) do
        py = FactoryGirl.create(:plan_year)
        bg = FactoryGirl.create(:benefit_group, effective_on_kind: 'first_of_month', effective_on_offset: 60,  plan_year: py)
        PlanYear.find(py.id)
      end

      it 'should return earliest_eligible_date as new hire enrollment period end date' do
        expected_end_date = (hired_on + 60.days)
        expected_end_date = (hired_on + 60.days).end_of_month + 1.day if expected_end_date.day != 1
        expect(census_employee.new_hire_enrollment_period.max).to eq (expected_end_date).end_of_day
      end
    end

    context 'when earliest effective date less than 30 days from current date' do
      let(:plan_year) do
        py = FactoryGirl.create(:plan_year)
        bg = FactoryGirl.create(:benefit_group, plan_year: py)
        PlanYear.find(py.id)
      end

      it 'should return 30 days from new hire enrollment period start as end date' do
        expect(census_employee.new_hire_enrollment_period.max).to eq (census_employee.new_hire_enrollment_period.min + 30.days).end_of_day
      end
    end
  end

  context '.earliest_eligible_date' do
    let(:hired_on){ TimeKeeper.date_of_record }

    let(:plan_year) do
      py = FactoryGirl.create(:plan_year)
      bg = FactoryGirl.create(:benefit_group, effective_on_kind: 'first_of_month', effective_on_offset: 60,  plan_year: py)
      PlanYear.find(py.id)
    end

    let(:census_employee) { CensusEmployee.new(**valid_params) }
    let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    it 'should return earliest effective date' do
      eligible_date = (hired_on + 60.days)
      eligible_date = (hired_on + 60.days).end_of_month + 1.day if eligible_date.day != 1
      expect(census_employee.earliest_eligible_date).to eq eligible_date
    end
  end

  context 'Validating CensusEmployee Termination Date' do
    let(:census_employee) { CensusEmployee.new(**valid_params) }

    it 'should return true when census employee is not terminated' do
      expect(census_employee.valid?).to be_truthy
    end

    it 'should return false when census employee date is not within 60 days' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_falsey
    end

    it 'should return true when census employee is already terminated' do
      census_employee.hired_on = TimeKeeper.date_of_record - 120.days
      census_employee.save! # set initial state
      census_employee.aasm_state = "employment_terminated"
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 90.days
      expect(census_employee.valid?).to be_truthy
    end
  end

  context '.find_or_build_benefit_group_assignment' do
    
    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
    let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
    let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
    let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

    it 'should have benefit group assignments assigned with both active and renewal plan year' do
      expect(census_employee.benefit_group_assignments.size).to eq 2
      expect(census_employee.active_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.active_benefit_group_assignment.benefit_group).to eq active_benefit_group
      expect(census_employee.renewal_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.renewal_benefit_group_assignment.benefit_group).to eq renewal_benefit_group
    end
  end

  context '.find_or_create_benefit_group_assignment' do

    let!(:plan_year) { FactoryGirl.create(:plan_year, start_on: Date.new(2015,10,1) ) }
    let!(:blue_collar_benefit_group) { FactoryGirl.create(:benefit_group, :premiums_for_2015, title: "blue collar benefit group", plan_year: plan_year) }
    let!(:employer_profile) { plan_year.employer_profile }
    let!(:white_collar_benefit_group) { FactoryGirl.create(:benefit_group, :premiums_for_2015, plan_year: plan_year, title: "white collar benefit group") }
    let!(:census_employee) { CensusEmployee.create(**valid_params) }

    before do
      census_employee.benefit_group_assignments.each{|bg| bg.delete} 
    end

    context 'when benefit group assignment with benefit group already exists' do
      let!(:blue_collar_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: false) }
      let!(:white_collar_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: white_collar_benefit_group, census_employee: census_employee, is_active: true) }

      it 'should activate existing benefit_group_assignment' do
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment).to eq white_collar_benefit_group_assignment
        census_employee.find_or_create_benefit_group_assignment(blue_collar_benefit_group)
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment).to eq blue_collar_benefit_group_assignment
      end
    end

    context 'when multiple benefit group assignments with benefit group exists' do
      let!(:blue_collar_benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 2.days, is_active: false) }
      let!(:blue_collar_benefit_group_assignment2)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 1.day, is_active: false) }
      let!(:blue_collar_benefit_group_assignment3)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: false) }
      let!(:white_collar_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: white_collar_benefit_group, census_employee: census_employee, is_active: true) }

      before do
        blue_collar_benefit_group_assignment1.aasm_state = 'coverage_selected'
        blue_collar_benefit_group_assignment1.save!(:validate => false)
        blue_collar_benefit_group_assignment2.aasm_state = 'coverage_waived'
        blue_collar_benefit_group_assignment2.save!(:validate => false)
      end

      it 'should activate benefit group assignment with valid enrollment status' do
        expect(census_employee.benefit_group_assignments.size).to eq 4
        expect(census_employee.active_benefit_group_assignment).to eq white_collar_benefit_group_assignment
        expect(blue_collar_benefit_group_assignment2.activated_at).to be_nil
        census_employee.find_or_create_benefit_group_assignment(blue_collar_benefit_group)
        expect(census_employee.benefit_group_assignments.size).to eq 4
        expect(census_employee.active_benefit_group_assignment).to eq blue_collar_benefit_group_assignment2
        expect(blue_collar_benefit_group_assignment2.activated_at).not_to be_nil
      end
    end

    context 'when none present with given benefit group' do
      let!(:blue_collar_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: true) }

      it 'should create new benefit group assignment' do
        expect(census_employee.benefit_group_assignments.size).to eq 1
        expect(census_employee.active_benefit_group_assignment.benefit_group).to eq blue_collar_benefit_group
        census_employee.find_or_create_benefit_group_assignment(white_collar_benefit_group)
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment.benefit_group).to eq white_collar_benefit_group
      end
    end
  end

  context '.enrollments_for_display' do

    let!(:employer_profile)          { FactoryGirl.create(:employer_profile) }
    let!(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: TimeKeeper.date_of_record) }
    let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }
    let!(:employee_role) { person.employee_roles.create( employer_profile: employer_profile, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
    let!(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }

    let(:plan_year_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
    let(:plan_year_end_on) { TimeKeeper.date_of_record.end_of_month + 1.year }
    let(:open_enrollment_start_on) { TimeKeeper.date_of_record.beginning_of_month }
    let(:open_enrollment_end_on) { open_enrollment_start_on + 12.days }
    let(:effective_date)         { plan_year_start_on }

    let!(:renewing_plan_year)                     { py = FactoryGirl.create(:plan_year,
                                                      start_on: plan_year_start_on,
                                                      end_on: plan_year_end_on,
                                                      open_enrollment_start_on: open_enrollment_start_on,
                                                      open_enrollment_end_on: open_enrollment_end_on,
                                                      employer_profile: employer_profile,
                                                      aasm_state: 'renewing_enrolled'
                                                    )

                                                    blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                    py.benefit_groups = [blue]
                                                    py.save(:validate => false)
                                                    py
                                                  }

    let!(:plan_year)                              { py = FactoryGirl.create(:plan_year,
                                                      start_on: plan_year_start_on - 1.year,
                                                      end_on: plan_year_end_on - 1.year,
                                                      open_enrollment_start_on: open_enrollment_start_on - 1.year,
                                                      open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days,
                                                      employer_profile: employer_profile,
                                                      aasm_state: 'active'
                                                    )

                                                    blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                    py.benefit_groups = [blue]
                                                    py.save(:validate => false)
                                                    py
                                                  }

    let!(:benefit_group_assignment) {
      BenefitGroupAssignment.create({
        census_employee: census_employee,
        benefit_group: plan_year.benefit_groups.first,
        start_on: plan_year_start_on - 1.year
      })
    }

    let!(:renewal_benefit_group_assignment) {
      BenefitGroupAssignment.create({
        census_employee: census_employee,
        benefit_group: renewing_plan_year.benefit_groups.first,
        start_on: plan_year_start_on
      })
    }

    let!(:health_enrollment)   { FactoryGirl.create(:hbx_enrollment,
      household: shop_family.latest_household,
      coverage_kind: "health",
      effective_on: effective_date - 1.year,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: effective_date - 11.months,
      benefit_group_id: plan_year.benefit_groups.first.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id
      )
    }

    let!(:dental_enrollment)   { FactoryGirl.create(:hbx_enrollment,
      household: shop_family.latest_household,
      coverage_kind: "dental",
      effective_on: effective_date - 1.year,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: effective_date - 11.months,
      benefit_group_id: plan_year.benefit_groups.first.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id
      )
    }

    let!(:auto_renewing_enrollment)   { FactoryGirl.create(:hbx_enrollment,
      household: shop_family.latest_household,
      coverage_kind: "health",
      effective_on: effective_date,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: effective_date,
      benefit_group_id: renewing_plan_year.benefit_groups.first.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: renewal_benefit_group_assignment.id,
      aasm_state: 'auto_renewing'
      )
    }

    context 'when current and renewing coverages present' do

      it 'should return both active and renewing coverages' do 
        expect(census_employee.enrollments_for_display).to eq [health_enrollment,dental_enrollment,auto_renewing_enrollment]
      end
    end
  end
  
  context 'editing a CensusEmployee SSN/DOB that is in a linked status' do
    let(:census_employee)     { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1977-01-01'.to_date, ssn: '123456789') }
    let(:person)              { FactoryGirl.create(:person,          first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '314159265') }

    let(:user)          { double("user") }
    let(:employee_role) {FactoryGirl.create(:employee_role)}


    it 'should allow Admins to edit a CensusEmployee SSN/DOB that is in a linked status' do
      allow(user).to receive(:has_hbx_staff_role?).and_return true # Admin
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow(employee_role).to receive(:census_employee).and_return census_employee
      allow(census_employee).to receive(:aasm_state).and_return "employee_role_linked"
      CensusEmployee.update_census_employee_records(person, user)
      expect(census_employee.ssn).to eq person.ssn
      expect(census_employee.dob).to eq person.dob
    end

    it 'should NOT allow Non-Admins to edit a CensusEmployee SSN/DOB that is in a linked status' do
      allow(user).to receive(:has_hbx_staff_role?).and_return false # Non-Admin
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow(employee_role).to receive(:census_employee).and_return census_employee
      allow(census_employee).to receive(:aasm_state).and_return "employee_role_linked"
      CensusEmployee.update_census_employee_records(person, user)
      expect(census_employee.ssn).not_to eq person.ssn
      expect(census_employee.dob).not_to eq person.dob
    end

  end

  context "check_hired_on_before_dob" do
    let(:census_employee) { FactoryGirl.build(:census_employee) }

    it "should fail" do
      census_employee.dob = TimeKeeper.date_of_record - 30.years
      census_employee.hired_on = TimeKeeper.date_of_record - 31.years
      expect(census_employee.save).to be_falsey
      expect(census_employee.errors[:hired_on].any?).to be_truthy
      expect(census_employee.errors[:hired_on].to_s).to match /date can't be before  date of birth/
    end
  end

  context '.renewal_benefit_group_assignment' do
    let(:census_employee) { CensusEmployee.new(**valid_params) }
    let(:benefit_group_assignment_one)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
    let(:benefit_group_assignment_two)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
    before do
      benefit_group_assignment_two.update_attribute(:updated_at, benefit_group_assignment_two.updated_at + 1.day)
      benefit_group_assignment_one.plan_year.update_attribute(:aasm_state, "renewing_enrolled")
      benefit_group_assignment_two.plan_year.update_attribute(:aasm_state, "renewing_enrolled")
    end

    it "should select the latest renewal benefit group assignment" do
      expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_two
    end
  end
end
