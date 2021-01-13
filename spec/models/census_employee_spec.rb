# frozen_string_literal: true

require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe CensusEmployee, type: :model, dbclean: :around_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }

  let!(:employer_profile) {abc_profile}
  let!(:organization) {abc_organization}

  let!(:benefit_application) {initial_application}
  let!(:benefit_package) {benefit_application.benefit_packages.first}
  let!(:benefit_group) {benefit_package}
  let(:effective_period_start_on) {TimeKeeper.date_of_record.end_of_month + 1.day + 1.month}
  let(:effective_period_end_on) {effective_period_start_on + 1.year - 1.day}
  let(:effective_period) {effective_period_start_on..effective_period_end_on}

  let(:first_name) {"Lynyrd"}
  let(:middle_name) {"Rattlesnake"}
  let(:last_name) {"Skynyrd"}
  let(:name_sfx) {"PhD"}
  let(:ssn) {"230987654"}
  let(:dob) {TimeKeeper.date_of_record - 31.years}
  let(:gender) {"male"}
  let(:hired_on) {TimeKeeper.date_of_record - 14.days}
  let(:is_business_owner) {false}
  let(:address) {Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001")}
  let(:autocomplete) {" lynyrd skynyrd"}

  let(:valid_params) do
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
      address: address,
      benefit_sponsorship: organization.active_benefit_sponsorship
    }
  end

  describe "Model instance" do
    context "model Attributes" do
      it {is_expected.to have_field(:benefit_sponsors_employer_profile_id).of_type(BSON::ObjectId)}
      it {is_expected.to have_field(:expected_selection).of_type(String).with_default_value_of("enroll")}
      it {is_expected.to have_field(:hired_on).of_type(Date)}
    end

    context "Associations" do
      it {is_expected.to embed_many(:benefit_group_assignments)}
      it {is_expected.to embed_many(:census_dependents)}
      it {is_expected.to belong_to(:benefit_sponsorship)}
    end

    context "Validations" do
      it {is_expected.to validate_presence_of(:ssn)}
      it {is_expected.to validate_presence_of(:benefit_sponsors_employer_profile_id)}
      it {is_expected.to validate_presence_of(:employer_profile_id)}
    end

    context "index" do
      it {is_expected.to have_index_for(aasm_state: 1)}
      it {is_expected.to have_index_for(encrypted_ssn: 1, dob: 1, aasm_state: 1)}
    end
  end

  describe "Model initialization", dbclean: :after_each do
    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(CensusEmployee.create(**params).valid?).to be_falsey
      end
    end

    context "with no employer profile" do
      let(:params) {valid_params.except(:employer_profile, :benefit_sponsorship)}

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

    context "validates expected_selection" do
      let(:params_expected_selection) {valid_params.merge(expected_selection: "enroll")}
      let(:params_in_valid) {valid_params.merge(expected_selection: "rspec-mock")}

      it "should have a valid value" do
        expect(CensusEmployee.create(**params_expected_selection).valid?).to be_truthy
      end

      it "should have a valid value" do
        expect(CensusEmployee.create(**params_in_valid).valid?).to be_falsey
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
      let(:params) {valid_params.merge({:is_business_owner => nil})}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_business_owner].any?).to be_truthy
      end
    end

    context "with all required attributes" do
      let(:params) {valid_params}
      let(:initial_census_employee) {CensusEmployee.new(**params)}

      it "should be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end

      it "should save" do
        expect(initial_census_employee.save).to be_truthy
      end

      it "should be findable by ID" do
        initial_census_employee.save
        expect(CensusEmployee.find(initial_census_employee.id)).to eq initial_census_employee
      end

      it "in an unlinked state" do
        expect(initial_census_employee.eligible?).to be_truthy
      end

      it "and should have the correct associated employer profile" do
        expect(initial_census_employee.employer_profile._id).to eq initial_census_employee.benefit_sponsors_employer_profile_id
      end

      it "should be findable by employer profile" do
        initial_census_employee.save
        expect(CensusEmployee.find_all_by_employer_profile(employer_profile).size).to eq 1
        expect(CensusEmployee.find_all_by_employer_profile(employer_profile).first).to eq initial_census_employee
      end
    end
  end

  describe "Censusdependents validators" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    let(:dependent) {CensusDependent.new(first_name: 'David', last_name: 'Henry', ssn: "", employee_relationship: "spouse", dob: TimeKeeper.date_of_record - 30.years, gender: "male")}
    let(:dependent2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333, dob: TimeKeeper.date_of_record - 30.years, gender: "male")}

    it "allow dependent ssn's to be updated to nil" do
      initial_census_employee.census_dependents = [dependent]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match(nil)
    end

    it "ignores dependent ssn's if ssn not nil" do
      initial_census_employee.census_dependents = [dependent2]
      initial_census_employee.save!
      expect(initial_census_employee.census_dependents.first.ssn).to match("333333333")
    end

    context "with duplicate ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}
      let(:child2) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: 333_333_333)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end

    context "with duplicate blank ssn's on dependents" do
      let(:child1) {FactoryBot.build(:census_dependent, first_name: 'Jimmy', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}
      let(:child2) {FactoryBot.build(:census_dependent, first_name: 'Ally', last_name: 'Stephens', employee_relationship: "child_under_26", ssn: "")}

      it "should not have errors" do
        initial_census_employee.census_dependents = [child1, child2]
        expect(initial_census_employee.valid?).to be_truthy
      end
    end

    context "with ssn matching subscribers" do
      let(:child1) {FactoryBot.build(:census_dependent, employee_relationship: "child_under_26", ssn: initial_census_employee.ssn)}

      it "should have errors" do
        initial_census_employee.census_dependents = [child1]
        expect(initial_census_employee.save).to be_falsey
        expect(initial_census_employee.errors[:base].first).to match(/SSN's must be unique for each dependent and subscriber/)
      end
    end


    context "and census employee identifying info is edited" do
      before {initial_census_employee.ssn = "606060606"}

      it "should be be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end
    end
  end

  describe "Cobrahire date checkers" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    context "check_cobra_begin_date" do
      it "should not have errors when existing_cobra is false" do
        initial_census_employee.cobra_begin_date = initial_census_employee.hired_on - 5.days
        initial_census_employee.existing_cobra = false
        expect(initial_census_employee.save).to be_truthy
      end

      context "when existing_cobra is true" do
        before do
          initial_census_employee.existing_cobra = 'true'
        end

        it "should not have errors when hired_on earlier than cobra_begin_date" do
          initial_census_employee.cobra_begin_date = initial_census_employee.hired_on + 5.days
          expect(initial_census_employee.save).to be_truthy
        end

        it "should have errors when hired_on later than cobra_begin_date" do
          initial_census_employee.cobra_begin_date = initial_census_employee.hired_on - 5.days
          expect(initial_census_employee.save).to be_falsey
          expect(initial_census_employee.errors[:cobra_begin_date].to_s).to match(/must be after Hire Date/)
        end
      end
    end
  end

  describe "Employee terminated" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    context "and employee is terminated and reported by employer on timely basis" do

      let(:termination_maximum) { Settings.aca.shop_market.retroactive_coverage_termination_maximum.to_hash }
      let(:earliest_retro_coverage_termination_date) {TimeKeeper.date_of_record.advance(termination_maximum).end_of_month }
      let(:earliest_valid_employment_termination_date) {earliest_retro_coverage_termination_date.beginning_of_month}
      let(:invalid_employment_termination_date) {earliest_valid_employment_termination_date - 1.day}
      let(:invalid_coverage_termination_date) {invalid_employment_termination_date.end_of_month}


      context "and the employment termination is reported later after max retroactive date" do

        before {initial_census_employee.terminate_employment!(invalid_employment_termination_date)}

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
        before {initial_census_employee.terminate_employment!(TimeKeeper.date_of_record + 10.days)}
        it "is in termination pending state" do
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end
      end

      context ".terminate_future_scheduled_census_employees" do
        it "should terminate the census employee on the day of the termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 2.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should not terminate the census employee if today's date < termination date" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 1.day)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employee_termination_pending"
        end

        it "should return the existing state of the census employee if today's date > termination date" do
          initial_census_employee.save
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record + 2.days, aasm_state: "employment_terminated")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record + 3.days)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end

        it "should also terminate the census employees if termination date is in the past" do
          initial_census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record - 3.days, aasm_state: "employee_termination_pending")
          CensusEmployee.terminate_future_scheduled_census_employees(TimeKeeper.date_of_record)
          expect(CensusEmployee.find(initial_census_employee.id).aasm_state).to eq "employment_terminated"
        end
      end

      context "and the termination date is within the retroactive reporting time period" do
        before {initial_census_employee.terminate_employment!(earliest_valid_employment_termination_date)}

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
          let!(:rehire) {initial_census_employee.replicate_for_rehire}

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

  describe "When Employee Role" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}

    context "and a benefit group isn't yet assigned to employee" do
      it "the roster instance should not be ready for linking" do
        initial_census_employee.benefit_group_assignments.delete_all
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end

    context "and a benefit group is assigned to employee" do
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee)}

      before do
        initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
        initial_census_employee.save
      end

      it "the employee census record should be ready for linking" do
        expect(initial_census_employee.may_link_employee_role?).to be_truthy
      end
    end

    context "and the benefit group plan year isn't published" do
      it "the roster instance should not be ready for linking" do
        benefit_application.cancel! if benefit_application.may_cancel?
        expect(initial_census_employee.may_link_employee_role?).to be_falsey
      end
    end
  end

  describe "When plan year is published" do
    let(:params) {valid_params}
    let(:initial_census_employee) {CensusEmployee.new(**params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee)}

    context "and a roster match by SSN and DOB is performed" do

      before do
        initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
        initial_census_employee.save
      end

      context "using non-matching ssn and dob" do
        let(:invalid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days, employer_profile: employer_profile)}

        it "should return an empty array" do
          expect(CensusEmployee.matchable(invalid_employee_role.ssn, invalid_employee_role.dob)).to eq []
        end
      end

      context "using matching ssn and dob" do
        let(:valid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile)}
        let!(:user) {FactoryBot.create(:user, person: valid_employee_role.person)}

        it "should return the roster instance" do
          expect(CensusEmployee.matchable(valid_employee_role.ssn, valid_employee_role.dob).collect(&:id)).to eq [initial_census_employee.id]
        end

        context "and a link employee role request is received" do
          context "and the provided employee role identifying information doesn't match a census employee" do
            let(:invalid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days, employer_profile: employer_profile)}

            it "should raise an error" do
              initial_census_employee.employee_role = invalid_employee_role
              expect(initial_census_employee.employee_role_linked?).to be_falsey
            end
          end

          context "and the provided employee role identifying information does match a census employee" do
            before do
              initial_census_employee.employee_role = valid_employee_role
            end

            it "should link the roster instance and employer role" do
              expect(initial_census_employee.employee_role_linked?).to be_truthy
            end

            context "and it is saved" do
              before {initial_census_employee.save}

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
            end
          end
        end
      end
    end

    context "and employer is renewing" do
    end

    context 'When there are two active benefit applications' do
      let(:current_year) {TimeKeeper.date_of_record.year}
      let(:effective_period) {current_effective_date..current_effective_date.next_year.prev_day}
      let(:open_enrollment_period) {effective_period.min.prev_month..(effective_period.min - 10.days)}
      let!(:service_areas2) {benefit_sponsorship.service_areas_on(effective_period.min)}
      let!(:benefit_sponsor_catalog2) {benefit_sponsorship.benefit_sponsor_catalog_for(effective_period.min)}
      let!(:initial_application2) do
        BenefitSponsors::BenefitApplications::BenefitApplication.new(
          benefit_sponsor_catalog: benefit_sponsor_catalog2,
          effective_period: effective_period,
          aasm_state: :active,
          open_enrollment_period: open_enrollment_period,
          recorded_rating_area: rating_area,
          recorded_service_areas: service_areas2,
          fte_count: 5,
          pte_count: 0,
          msp_count: 0
        )
      end
      let(:product_package2) {initial_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind == package_kind}}
      let(:current_benefit_package2) {build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package2, title: "second benefit package", benefit_application: initial_application2)}


      before do
        FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: current_benefit_package2, census_employee: initial_census_employee)
        initial_application2.benefit_packages = [current_benefit_package2]
        benefit_sponsorship.benefit_applications = [initial_application2]
        benefit_sponsorship.save!
        initial_census_employee.save
      end

      it 'should only pick active benefit group assignment - first benefit package' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: false, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: true, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'first benefit package'
      end

      it 'should pick latest benefit group assignment if all the assignments are inactive' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: false, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: false, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'second benefit package'
      end

      it 'should only pick active benefit group assignment - second benefit package' do
        initial_census_employee.benefit_group_assignments[0].update_attributes(is_active: true, created_at: Date.new(current_year, 2, 21))
        initial_census_employee.benefit_group_assignments[1].update_attributes(is_active: false, created_at: Date.new(current_year - 1, 2, 21))
        expect(initial_census_employee.published_benefit_group.title).to eq 'second benefit package'
      end
    end
  end

  context "multiple employers have active, terminated and rehired employees" do
    let(:today) {TimeKeeper.date_of_record}
    let(:one_month_ago) {today - 1.month}
    let(:last_month) {one_month_ago.beginning_of_month..one_month_ago.end_of_month}
    let(:last_year_to_date) {(today - 1.year)..today}

    let(:er1_active_employee_count) {2}
    let(:er1_terminated_employee_count) {1}
    let(:er1_rehired_employee_count) {1}

    let(:er2_active_employee_count) {1}
    let(:er2_terminated_employee_count) {1}

    let(:employee_count) do
      er1_active_employee_count +
        er1_terminated_employee_count +
        er1_rehired_employee_count +
        er2_active_employee_count +
        er2_terminated_employee_count
    end

    let(:terminated_today_employee_count) {2}
    let(:terminated_last_month_employee_count) {1}
    let(:er1_termination_count) {er1_terminated_employee_count + er1_rehired_employee_count}

    let(:terminated_employee_count) {er1_terminated_employee_count + er2_terminated_employee_count}
    let(:termed_status_employee_count) {terminated_employee_count + er1_rehired_employee_count}

    let(:employer_count) {2} # We're only creating 2 ER profiles

    let(:employer_profile_1) {abc_profile}
    let(:organization1) {abc_organization}

    let(:aasm_state) {:active}
    let(:package_kind) {:single_issuer}
    let(:effective_period) {current_effective_date..current_effective_date.next_year.prev_day}
    let(:open_enrollment_period) {effective_period.min.prev_month..(effective_period.min - 10.days)}
    let!(:employer_profile_2) {FactoryBot.create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site, site: organization.site)}
    let(:organization2) {employer_profile_2.organization}
    let!(:benefit_sponsorship2) do
      sponsorship = employer_profile_2.add_benefit_sponsorship
      sponsorship.save
      sponsorship
    end
    let!(:service_areas2) {benefit_sponsorship2.service_areas_on(effective_period.min)}
    let(:benefit_sponsor_catalog2) {benefit_sponsorship2.benefit_sponsor_catalog_for(effective_period.min)}
    let(:initial_application2) do
      BenefitSponsors::BenefitApplications::BenefitApplication.new(
        benefit_sponsor_catalog: benefit_sponsor_catalog2,
        effective_period: effective_period,
        aasm_state: aasm_state,
        open_enrollment_period: open_enrollment_period,
        recorded_rating_area: rating_area,
        recorded_service_areas: service_areas2,
        fte_count: 5,
        pte_count: 0,
        msp_count: 0
      )
    end
    let(:product_package2) {initial_application.benefit_sponsor_catalog.product_packages.detect {|package| package.package_kind == package_kind}}
    let(:current_benefit_package2) {build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package2, benefit_application: initial_application2)}


    let(:er1_active_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_active_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er1_terminated_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_terminated_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er1_rehired_employees) do
      FactoryBot.create_list(
        :census_employee,
        er1_rehired_employee_count,
        employer_profile: employer_profile_1,
        benefit_sponsorship: organization1.active_benefit_sponsorship
      )
    end
    let(:er2_active_employees) do
      FactoryBot.create_list(
        :census_employee,
        er2_active_employee_count,
        employer_profile: employer_profile_2,
        benefit_sponsorship: organization2.active_benefit_sponsorship
      )
    end
    let(:er2_terminated_employees) do
      FactoryBot.create_list(
        :census_employee,
        er2_terminated_employee_count,
        employer_profile: employer_profile_2,
        benefit_sponsorship: organization2.active_benefit_sponsorship
      )
    end

    before do
      initial_application2.benefit_packages = [current_benefit_package2]
      benefit_sponsorship2.benefit_applications = [initial_application2]
      benefit_sponsorship2.save!

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
      expect(BenefitSponsors::Organizations::Organization.all.employer_profiles.size).to eq employer_count
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

    let!(:existing_census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship
      )
    end

    let!(:person) do
      Person.create(
        first_name: existing_census_employee.first_name,
        last_name: existing_census_employee.last_name,
        ssn: existing_census_employee.ssn,
        dob: existing_census_employee.dob,
        gender: existing_census_employee.gender
      )
    end
    let!(:user) {create(:user, person: person)}
    let!(:employee_role) do
      EmployeeRole.create(
        person: person,
        hired_on: existing_census_employee.hired_on,
        employer_profile: existing_census_employee.employer_profile
      )
    end

    it "existing record should be findable" do
      expect(CensusEmployee.find(existing_census_employee.id)).to be_truthy
    end

    context "and a new census employee instance, with same ssn same employer profile is built" do
      let!(:duplicate_census_employee) {existing_census_employee.dup}

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
          let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: existing_census_employee)}

          let!(:saved_census_employee) do
            ee = CensusEmployee.find(existing_census_employee.id)
            ee.benefit_group_assignments = [benefit_group_assignment]
            ee.save
            ee
          end

          context "and publish the plan year and associate census employee with employee_role" do
            before do
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
                saved_census_employee.terminate_employment(TimeKeeper.date_of_record - 1.day)
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
              let(:employee_role_linked_state) {saved_census_employee.dup}
              let(:employment_terminated_state) {saved_census_employee.dup}
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

  context "validation for employment_terminated_on" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship, hired_on: TimeKeeper.date_of_record.beginning_of_year - 50.days)}

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
      census_employee.employment_terminated_on = TimeKeeper.date_of_record - 1.day
      expect(census_employee.valid?).to be_truthy
      expect(census_employee.errors[:employment_terminated_on].any?).to be_falsey
    end
  end

  context "validation for census_dependents_relationship" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:spouse1) {FactoryBot.build(:census_dependent, employee_relationship: "spouse")}
    let(:spouse2) {FactoryBot.build(:census_dependent, employee_relationship: "spouse")}
    let(:partner1) {FactoryBot.build(:census_dependent, employee_relationship: "domestic_partner")}
    let(:partner2) {FactoryBot.build(:census_dependent, employee_relationship: "domestic_partner")}

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
    let(:census_employee1) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Amy",
        last_name: "Frank"
      )
    end

    let(:census_employee2) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Javert",
        last_name: "Burton"
      )
    end

    let(:census_employee3) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        first_name: "Burt",
        last_name: "Love"
      )
    end

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

    let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile)}
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        benefit_sponsorship: employer_profile.active_benefit_sponsorship,
        employer_profile: employer_profile,
        employee_role_id: employee_role.id
      )
    end

    let(:person) {double}
    let(:family) {double(active_household: double(hbx_enrollments: double(shop_market: double(enrolled_and_renewing: double(open_enrollments: [@enrollment])))))}

    let(:benefit_group) {double}

    before :each do
      family = FactoryBot.create(:family, :with_primary_family_member)
      @enrollment = FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)
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
      @enrollment.reload
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

  describe 'scopes' do
    context 'by_benefit_package_and_assignment_on_or_later' do
      include_context "setup employees"
      before do
        date = TimeKeeper.date_of_record.beginning_of_month
        bga = census_employees.first.benefit_group_assignments.first
        bga.assign_attributes(start_on: date + 1.month)
        bga.save(validate: false)
        bga2 = census_employees.second.benefit_group_assignments.first
        bga2.assign_attributes(start_on: date - 1.month)
        bga2.save(validate: false)
        census_employees.third.benefit_group_assignments.first.update_attributes(is_active: false)

         @census_employees = CensusEmployee.by_benefit_package_and_assignment_on_or_later(initial_application.benefit_packages.first, date, true)
      end

       it "should return more than one" do
        expect(@census_employees.count).to eq 3
      end

       it 'Should include CE' do
        [census_employees.first.id, census_employees[3].id, census_employees[4].id].each do |ce_id|
          expect(@census_employees.pluck(:id)).to include(ce_id)
        end
      end

       it 'should not include CE' do
        [census_employees[1].id, census_employees[2].id].each do |ce_id|
          expect(@census_employees.pluck(:id)).not_to include(ce_id)
        end
      end
    end
  end

  describe 'construct_employee_role', dbclean: :after_each do
    let(:user)  { FactoryBot.create(:user) }
    context 'when employee_role present' do
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile) }
      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          employee_role_id: employee_role.id
        )
      end
      before do
        person = employee_role.person
        person.user = user
        person.save
        census_employee.construct_employee_role
        census_employee.reload
      end
      it "should return true when link_employee_role!" do
        expect(census_employee.aasm_state).to eq('employee_role_linked')
      end
    end

    context 'when employee_role not present' do
      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
        )
      end
      before do
        census_employee.construct_employee_role
        census_employee.reload
      end
      it { expect(census_employee.aasm_state).to eq('eligible') }
    end
  end

  context "construct_employee_role_for_match_person" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:person) do
      FactoryBot.create(
        :person,
        first_name: census_employee.first_name,
        last_name: census_employee.last_name,
        dob: census_employee.dob,
        ssn: census_employee.ssn,
        gender: census_employee.gender
      )
    end
    let(:census_employee1) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee1)}


    it "should return false when not match person" do
      expect(census_employee1.construct_employee_role_for_match_person).to eq false
    end

    it "should return false when match person which has active employee role for current census employee" do
      census_employee.update_attributes(benefit_sponsors_employer_profile_id: employer_profile.id)
      person.employee_roles.create!(ssn: census_employee.ssn,
                                    benefit_sponsors_employer_profile_id: census_employee.employer_profile.id,
                                    census_employee_id: census_employee.id,
                                    hired_on: census_employee.hired_on)
      expect(census_employee.construct_employee_role_for_match_person).to eq false
    end

    it "should return true when match person has no active employee roles for current census employee" do
      person.employee_roles.create!(ssn: census_employee.ssn,
                                    benefit_sponsors_employer_profile_id: census_employee.employer_profile.id,
                                    hired_on: census_employee.hired_on)
      expect(census_employee.construct_employee_role_for_match_person).to eq true
    end

    it "should send email notification for non conversion employee" do
      allow(census_employee1).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      person.employee_roles.create!(ssn: census_employee1.ssn,
                                    employer_profile_id: census_employee1.employer_profile.id,
                                    hired_on: census_employee1.hired_on)
      expect(census_employee1.send_invite!).to eq true
    end
  end

  context "newhire_enrollment_eligible" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}
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

  context ".is_employee_in_term_pending?", dbclean: :after_each  do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"

    let(:employer_profile) {abc_organization.employer_profile}
    let(:benefit_application) { abc_organization.employer_profile.benefit_applications.where(aasm_state: :active).first }

    let(:plan_year_start_on) {benefit_application.start_on}
    let(:plan_year_end_on) {benefit_application.end_on}

    let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee,
                                             benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                                             employer_profile: employer_profile,
                                             created_at: (plan_year_start_on + 10.days),
                                             updated_at: (plan_year_start_on + 10.days),
                                             hired_on: (plan_year_start_on + 10.days)
    )}

    it 'should return false if census employee is not terminated' do
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return false if census employee has no active benefit group assignment' do
      draft_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :draft).first.benefit_packages.first
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: draft_benefit_group, start_on: draft_benefit_group.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return false if census employee is terminated but has no active benefit group assignment' do
      draft_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :draft).first.benefit_packages.first
      census_employee.update_attributes(employment_terminated_on: draft_benefit_group.end_on - 5.days)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: draft_benefit_group, start_on: draft_benefit_group.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end

    it 'should return true if census employee is terminated with future date which falls under active PY' do
      active_benefit_package =  census_employee.active_benefit_group_assignment.benefit_package
      census_employee.update_attributes(employment_terminated_on: active_benefit_package.end_on - 5.days)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: active_benefit_package, start_on: active_benefit_package.benefit_application.start_on)
      expect(census_employee.is_employee_in_term_pending?).to eq true
    end

    it 'should return false if census employee has no active benefit group assignment' do
      active_benefit_package = census_employee.active_benefit_group_assignment.benefit_package
      census_employee.update_attributes(employment_terminated_on: active_benefit_package.end_on - 1.month)
      census_employee.existing_cobra = 'true'
      expect(census_employee.is_employee_in_term_pending?).to eq false
    end
  end

  context "generate_and_deliver_checkbook_url" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:hbx_enrollment) {HbxEnrollment.new(coverage_kind: 'health', family: family)}
    let(:plan) {FactoryBot.create(:plan)}
    let(:builder_class) {"ShopEmployerNotices::OutOfPocketNotice"}
    let(:builder) {instance_double(builder_class, :deliver => true)}
    let(:notice_triggers) {double("notice_triggers")}
    let(:notice_trigger) {instance_double("NoticeTrigger", :notice_template => "template", :mpi_indicator => "mpi_indicator")}

    before do
      allow(employer_profile).to receive(:plan_years).and_return([benefit_application])
      allow(census_employee).to receive(:employer_profile).and_return(employer_profile)
      allow(census_employee).to receive_message_chain(:employer_profile, :plan_years).and_return([benefit_application])
      allow(census_employee).to receive_message_chain(:active_benefit_group, :reference_plan).and_return(plan)
      allow(notice_triggers).to receive(:first).and_return(notice_trigger)
      allow(notice_trigger).to receive_message_chain(:notice_builder, :classify).and_return(builder_class)
      allow(notice_trigger).to receive_message_chain(:notice_builder, :safe_constantize, :new).and_return(builder)
      allow(notice_trigger).to receive_message_chain(:notice_trigger_element_group, :notice_peferences).and_return({})
      allow(ApplicationEventKind).to receive_message_chain(:where, :first).and_return(double("ApplicationEventKind", {:notice_triggers => notice_triggers, :title => "title", :event_name => "OutOfPocketNotice"}))
      allow_any_instance_of(Services::CheckbookServices::PlanComparision).to receive(:generate_url).and_return("fake_url")
    end
    context "#generate_and_deliver_checkbook_url" do
      it "should create a builder and deliver without expection" do
        expect {census_employee.generate_and_deliver_checkbook_url}.not_to raise_error
      end

      it 'should trigger deliver' do
        expect(builder).to receive(:deliver)
        census_employee.generate_and_deliver_checkbook_url
      end
    end

    context "#generate_and_save_to_temp_folder " do
      it "should builder and save without expection" do
        expect {census_employee.generate_and_save_to_temp_folder}.not_to raise_error
      end

      it 'should not trigger deliver' do
        expect(builder).not_to receive(:deliver)
        census_employee.generate_and_save_to_temp_folder
      end
    end
  end

  context "terminating census employee on the roster & actions on existing enrollments", dbclean: :around_each do

    context "change the aasm state & populates terminated on of enrollments" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
        )
      end

      let(:employee_role) {FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile)}
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}

      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'health', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_two) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, coverage_kind: 'dental', employee_role_id: employee_role.id)}
      let(:hbx_enrollment_three) {FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_group.id, household: family.active_household, aasm_state: 'renewing_waived', employee_role_id: employee_role.id)}
      let(:assignment) {double("BenefitGroupAssignment", benefit_package: benefit_group)}

      before do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(assignment)
        allow(HbxEnrollment).to receive(:find_enrollments_by_benefit_group_assignment).and_return([hbx_enrollment, hbx_enrollment_two, hbx_enrollment_three], [])
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      termination_dates = [TimeKeeper.date_of_record - 5.days, TimeKeeper.date_of_record, TimeKeeper.date_of_record + 5.days]
      termination_dates.each do |terminated_on|

        context 'move the enrollment into proper state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the health enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            expect(hbx_enrollment.reload.terminated_on).to eq census_employee.earliest_coverage_termination_on(terminated_on)
          end

          it "should move the dental enrollment to pending/terminated status" do
            coverage_end = census_employee.earliest_coverage_termination_on(terminated_on)
            if coverage_end < TimeKeeper.date_of_record
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_terminated'
            else
              expect(hbx_enrollment_two.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end
        end

        context 'move the enrollment aasm state to cancel status' do

          before do
            hbx_enrollment.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            hbx_enrollment_two.update_attribute(:effective_on, TimeKeeper.date_of_record.next_month)
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should cancel the health enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the health enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end

          it "should cancel the dental enrollment if effective date is in future" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_canceled'
            else
              expect(hbx_enrollment.reload.aasm_state).to eq 'coverage_termination_pending'
            end
          end

          it "should set the coverage termination on date on the dental enrollment" do
            if census_employee.coverage_terminated_on < hbx_enrollment.effective_on
              expect(hbx_enrollment_two.reload.terminated_on).to eq nil
            else
              expect(hbx_enrollment.reload.terminated_on).to eq census_employee.coverage_terminated_on
            end
          end
        end

        context 'move to enrollment aasm state to inactive state' do

          before do
            # we do not want to trigger notice
            # takes too much time on processing
            allow_any_instance_of(BenefitSponsors::ModelEvents::HbxEnrollment).to receive(:notify_on_save).and_return(nil)
            census_employee.terminate_employment!(terminated_on)
          end

          it "should move the waived enrollment to inactive state" do
            expect(hbx_enrollment_three.reload.aasm_state).to eq 'inactive' if terminated_on >= TimeKeeper.date_of_record
          end

          it "should set the coverage termination on date on the dental enrollment" do
            expect(hbx_enrollment_three.reload.terminated_on).to eq nil
          end
        end
      end
    end


  end

  context '.new_hire_enrollment_period' do

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    context 'when hired_on date is in the past' do
      it 'should return census employee created date as new hire enrollment period start date' do
        # created_at will have default utc time zone
        time_zone = TimeKeeper.date_according_to_exchange_at(census_employee.created_at).beginning_of_day
        expect(census_employee.new_hire_enrollment_period.min).to eq time_zone
      end
    end

    context 'when hired_on date is in the future' do
      let(:hired_on) {TimeKeeper.date_of_record + 14.days}

      it 'should return hired_on date as new hire enrollment period start date' do
        expect(census_employee.new_hire_enrollment_period.min).to eq census_employee.hired_on
      end
    end

    context 'when earliest effective date is in future more than 30 days from current date' do
      let(:hired_on) {TimeKeeper.date_of_record}

      it 'should return earliest_eligible_date as new hire enrollment period end date' do
        # TODO: - Fix Effective On For & Eligible On on benefit package
        expected_end_date = (hired_on + 60.days)
        expected_end_date = (hired_on + 60.days).end_of_month + 1.day if expected_end_date.day != 1
        # expect(census_employee.new_hire_enrollment_period.max).to eq (expected_end_date).end_of_day
      end
    end

    context 'when earliest effective date less than 30 days from current date' do

      it 'should return 30 days from new hire enrollment period start as end date' do
        expect(census_employee.new_hire_enrollment_period.max).to eq (census_employee.new_hire_enrollment_period.min + 30.days).end_of_day
      end
    end
  end

  context '.earliest_eligible_date' do
    let(:hired_on) {TimeKeeper.date_of_record}

    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      census_employee.save!
      # benefit_group.plan_year.update_attributes(:aasm_state => 'published')
    end

    it 'should return earliest effective date' do
      # TODO: - Fix Effective On For & Eligible On on benefit package
      eligible_date = (hired_on + 60.days)
      eligible_date = (hired_on + 60.days).end_of_month + 1.day if eligible_date.day != 1
      # expect(census_employee.earliest_eligible_date).to eq eligible_date
    end
  end

  context 'Validating CensusEmployee Termination Date' do
    let(:census_employee) {CensusEmployee.new(**valid_params)}

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

  context '.assign_default_benefit_package' do
    include_context "setup renewal application"

    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship
      )
    end
    let!(:benefit_group_assignment1) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: census_employee, is_active: false)}

    it 'should have active benefit group assignment' do
      expect(census_employee.active_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.active_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.active_benefit_application.benefit_packages.first
    end

    it 'should have renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      expect(census_employee.renewal_benefit_group_assignment.present?).to be_truthy
      expect(census_employee.renewal_benefit_group_assignment.benefit_package).to eq benefit_sponsorship.renewal_benefit_application.benefit_packages.first
    end

    it 'should have most recent renewal benefit group assignment' do
      renewal_application.update_attributes(predecessor_id: benefit_application.id)
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_group_assignment1.update_attributes(created_at: census_employee.benefit_group_assignments.last.created_at + 1.day)
      census_employee.benefit_group_assignments << benefit_group_assignment1
      expect(census_employee.renewal_benefit_group_assignment.created_at).to eq benefit_group_assignment1.created_at
    end
  end

  context '.find_or_create_benefit_group_assignment' do

    let(:benefit_application) {initial_application}
    let(:organization) {initial_application.benefit_sponsorship.profile.organization}
    let!(:blue_collar_benefit_group) {FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, title: "blue collar benefit group", benefit_application: benefit_application)}
    let!(:employer_profile) {organization.employer_profile}
    let!(:white_collar_benefit_group) {FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, title: "white collar benefit group")}
    let!(:census_employee) {CensusEmployee.create(**valid_params)}

    before do
      census_employee.benefit_group_assignments.delete_all
    end

    context 'when benefit group assignment with benefit group already exists' do
      let!(:blue_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: false)}
      let!(:white_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: white_collar_benefit_group, census_employee: census_employee, is_active: true)}

      it 'should activate existing benefit_group_assignment' do
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment).to eq white_collar_benefit_group_assignment
        census_employee.find_or_create_benefit_group_assignment([blue_collar_benefit_group])
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment).to eq blue_collar_benefit_group_assignment
      end
    end

    context 'when multiple benefit group assignments with benefit group exists' do
      let!(:blue_collar_benefit_group_assignment1) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 2.days, is_active: false)}
      let!(:blue_collar_benefit_group_assignment2) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, created_at: TimeKeeper.date_of_record - 1.day, is_active: false)}
      let!(:blue_collar_benefit_group_assignment3) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: false)}
      let!(:white_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: white_collar_benefit_group, census_employee: census_employee, is_active: true)}

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
        census_employee.find_or_create_benefit_group_assignment([blue_collar_benefit_group])
        expect(census_employee.benefit_group_assignments.size).to eq 4
        expect(census_employee.active_benefit_group_assignment).to eq blue_collar_benefit_group_assignment2
        expect(blue_collar_benefit_group_assignment2.activated_at).not_to be_nil
      end
    end

    context 'when none present with given benefit group' do
      let!(:blue_collar_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: blue_collar_benefit_group, census_employee: census_employee, is_active: true)}
      it 'should create new benefit group assignment' do
        expect(census_employee.benefit_group_assignments.size).to eq 1
        expect(census_employee.active_benefit_group_assignment.benefit_group).to eq blue_collar_benefit_group
        census_employee.find_or_create_benefit_group_assignment([white_collar_benefit_group])
        expect(census_employee.benefit_group_assignments.size).to eq 2
        expect(census_employee.active_benefit_group_assignment.benefit_group).to eq white_collar_benefit_group
      end
    end
  end

  context "current_state" do
    let(:census_employee) {CensusEmployee.new}

    context "existing_cobra is true" do
      before :each do
        census_employee.existing_cobra = 'true'
      end

      it "should return cobra_terminated" do
        census_employee.aasm_state = CensusEmployee::COBRA_STATES.last
        expect(census_employee.current_state).to eq CensusEmployee::COBRA_STATES.last.humanize
      end
    end

    context "existing_cobra is false" do
      it "should return aasm_state" do
        expect(census_employee.current_state).to eq 'eligible'.humanize
      end
    end
  end

  context "is_cobra_status?" do
    let(:census_employee) {CensusEmployee.new}

    context 'when existing_cobra is true' do
      before :each do
        census_employee.existing_cobra = 'true'
      end

      it "should return true" do
        expect(census_employee.is_cobra_status?).to be_truthy
      end

      it "aasm_state should be cobra_eligible" do
        expect(census_employee.aasm_state).to eq 'cobra_eligible'
      end
    end

    context "when existing_cobra is false" do
      before :each do
        census_employee.existing_cobra = false
      end

      it "should return false when aasm_state not equal cobra" do
        census_employee.aasm_state = 'eligible'
        expect(census_employee.is_cobra_status?).to be_falsey
      end

      it "should return true when aasm_state equal cobra_linked" do
        census_employee.aasm_state = 'cobra_linked'
        expect(census_employee.is_cobra_status?).to be_truthy
      end
    end
  end

  context "existing_cobra" do
    # let(:census_employee) { FactoryBot.create(:census_employee) }
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true" do
      CensusEmployee::COBRA_STATES.each do |state|
        census_employee.aasm_state = state
        expect(census_employee.existing_cobra).to be_truthy
      end
    end
  end

  context "have_valid_date_for_cobra with current_user" do
    let(:census_employee100) { FactoryBot.create(:census_employee) }
    let(:person100) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user100) { FactoryBot.create(:user, person: person100) }

    it "should return false even if current_user is a valid admin" do
      expect(census_employee100.have_valid_date_for_cobra?(user100)).to eq false
    end

    it "should return false as census_employee doesn't meet the requirements" do
      expect(census_employee100.have_valid_date_for_cobra?).to eq false
    end
  end

  context "have_valid_date_for_cobra?" do
    let(:hired_on) {TimeKeeper.date_of_record}
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship,
        hired_on: hired_on
      )
    end

    before :each do
      census_employee.terminate_employee_role!
    end

    it "can cobra employee_role" do
      census_employee.cobra_begin_date = hired_on + 10.days
      census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
      census_employee.cobra_begin_date = TimeKeeper.date_of_record
      expect(census_employee.may_elect_cobra?).to be_truthy
    end

    it "can not cobra employee_role" do
      census_employee.cobra_begin_date = hired_on + 10.days
      census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months - 5.days
      census_employee.cobra_begin_date = TimeKeeper.date_of_record
      expect(census_employee.may_elect_cobra?).to be_falsey
    end

    context "current date is less then 6 months after coverage_terminated_on" do
      before :each do
        census_employee.cobra_begin_date = hired_on + 10.days
        census_employee.coverage_terminated_on = TimeKeeper.date_of_record - Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
      end

      it "when cobra_begin_date is early than coverage_terminated_on" do
        census_employee.cobra_begin_date = census_employee.coverage_terminated_on - 5.days
        expect(census_employee.may_elect_cobra?).to be_falsey
      end

      it "when cobra_begin_date is later than 6 months after coverage_terminated_on" do
        census_employee.cobra_begin_date = census_employee.coverage_terminated_on + Settings.aca.shop_market.cobra_enrollment_period.months.months + 5.days
        expect(census_employee.may_elect_cobra?).to be_falsey
      end
    end

    it "can not cobra employee_role" do
      census_employee.cobra_begin_date = hired_on - 10.days
      expect(census_employee.may_elect_cobra?).to be_falsey
    end

    it "can not cobra employee_role without cobra_begin_date" do
      census_employee.cobra_begin_date = nil
      expect(census_employee.may_elect_cobra?).to be_falsey
    end
  end

  context "can_elect_cobra?" do
    let(:census_employee) do
      FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship,
        hired_on: hired_on
      )
    end

    it "should return false when aasm_state is eligible" do
      expect(census_employee.can_elect_cobra?).to be_falsey
    end

    it "should return true when aasm_state is employment_terminated" do
      census_employee.aasm_state = 'employment_terminated'
      expect(census_employee.can_elect_cobra?).to be_truthy
    end

    it "should return true when aasm_state is cobra_terminated" do
      census_employee.aasm_state = 'cobra_terminated'
      expect(census_employee.can_elect_cobra?).to be_falsey
    end
  end

  context "show_plan_end_date?" do
    context "without coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.build(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          hired_on: hired_on
        )
      end

      (CensusEmployee::EMPLOYMENT_TERMINATED_STATES + CensusEmployee::COBRA_STATES).uniq.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end

    context "with coverage_terminated_on" do

      let(:census_employee) do
        FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship,
          coverage_terminated_on: TimeKeeper.date_of_record
        )
      end

      CensusEmployee::EMPLOYMENT_TERMINATED_STATES.each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_truthy
        end
      end

      (CensusEmployee::COBRA_STATES - CensusEmployee::EMPLOYMENT_TERMINATED_STATES).each do |state|
        it "should return false when aasm_state is #{state}" do
          census_employee.aasm_state = state
          expect(census_employee.show_plan_end_date?).to be_falsey
        end
      end
    end
  end

  context "is_cobra_coverage_eligible?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    let(:hbx_enrollment) do
      HbxEnrollment.new(
        aasm_state: "coverage_terminated",
        terminated_on: TimeKeeper.date_of_record,
        coverage_kind: 'health'
        # family: census_employee.employee_role.person.primary_family
      )
    end

    it "should return true when employement is terminated and " do
      allow(Family).to receive(:where).and_return([hbx_enrollment])
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record)
      allow(census_employee).to receive(:employment_terminated?).and_return(true)
      expect(census_employee.is_cobra_coverage_eligible?).to be_truthy
    end

    it "should return false when employement is not terminated" do
      allow(census_employee).to receive(:employment_terminated?).and_return(false)
      expect(census_employee.is_cobra_coverage_eligible?).to be_falsey
    end
  end

  context "cobra_eligibility_expired?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true when coverage is terminated more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record - 7.months)
      expect(census_employee.cobra_eligibility_expired?).to be_truthy
    end

    it "should return false when coverage is terminated not more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record - 2.months)
      expect(census_employee.cobra_eligibility_expired?).to be_falsey
    end

    it "should return true when employment terminated more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(nil)
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record - 7.months)
      expect(census_employee.cobra_eligibility_expired?).to be_truthy
    end

    it "should return false when employment terminated not more that 6 months " do
      allow(census_employee).to receive(:coverage_terminated_on).and_return(nil)
      allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record - 1.month)
      expect(census_employee.cobra_eligibility_expired?).to be_falsey
    end
  end


  context "is_linked?" do

    let(:census_employee) do
      FactoryBot.build(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: organization.active_benefit_sponsorship
      )
    end

    it "should return true when aasm_state is employee_role_linked" do
      census_employee.aasm_state = 'employee_role_linked'
      expect(census_employee.is_linked?).to be_truthy
    end

    it "should return true when aasm_state is cobra_linked" do
      census_employee.aasm_state = 'cobra_linked'
      expect(census_employee.is_linked?).to be_truthy
    end

    it "should return false" do
      expect(census_employee.is_linked?).to be_falsey
    end
  end

  context 'past_enrollment' do
    let!(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(
        :benefit_sponsors_employee_role,
        person: person,
        census_employee: ce,
        employer_profile: employer_profile
      )
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        family: census_employee.employee_role.person.primary_family,
        coverage_kind: "health",
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_terminated"
      )
    end
    let!(:family) { census_employee.employee_role.person.primary_family }

    it "should return enrollments" do
      expect(census_employee.past_enrollments.count).to eq 1
    end

    context 'should not return enrollment' do
      before do
        enrollment.update_attributes(external_enrollment: true)
      end

      it 'returns 0 enrollments' do
        expect(census_employee.past_enrollments.count).to eq(0)
      end
    end
  end

  context '.enrollments_for_display' do
    include_context "setup renewal application"

    let(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: ce, is_active: false)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let!(:auto_renewing_health_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
        aasm_state: "auto_renewing"
      )
    end

    let!(:auto_renewing_dental_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "dental",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
        aasm_state: "auto_renewing"
      )
    end

    let(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: census_employee.active_benefit_package.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_selected"
      )
    end


    shared_examples_for "enrollments for display" do |state, status, result|

      let!(:health_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "health",
          kind: "employer_sponsored",
          family: census_employee.employee_role.person.primary_family,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: census_employee.active_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
          aasm_state: state
        )
      end

      let!(:dental_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "dental",
          family: census_employee.employee_role.person.primary_family,
          kind: "employer_sponsored",
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: census_employee.active_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
          aasm_state: state
        )
      end

      it "should #{status}return #{state} health enrollment" do
        expect(census_employee.enrollments_for_display[0].try(:aasm_state) == state).to eq result
      end

      it "should #{status}return #{state} dental enrollment" do
        expect(census_employee.enrollments_for_display[1].try(:aasm_state) == state).to eq result
      end
    end

    it_behaves_like "enrollments for display", "coverage_selected", "", true
    it_behaves_like "enrollments for display", "coverage_enrolled", "", true
    it_behaves_like "enrollments for display", "coverage_termination_pending", "", true
    it_behaves_like "enrollments for display", "coverage_terminated", "not ", false
    it_behaves_like "enrollments for display", "coverage_expired", "not ", false
    it_behaves_like "enrollments for display", "shopping", "not ", false

    it 'should return auto renewing health enrollment' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      expect(census_employee.enrollments_for_display[0]).to eq auto_renewing_health_enrollment
    end

    it 'should return auto renewing dental enrollment' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      expect(census_employee.enrollments_for_display[1]).to eq auto_renewing_dental_enrollment
    end

    it "should return current and renewing coverages" do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      enrollment
      expect(census_employee.enrollments_for_display).to eq [enrollment, auto_renewing_health_enrollment, auto_renewing_dental_enrollment]
    end

    it 'has renewal_benefit_group_enrollments' do
      renewal_application.approve_application! if renewal_application.may_approve_application?
      benefit_sponsorship.benefit_applications << renewal_application
      benefit_sponsorship.save
      enrollment
      census_employee.reload
      expect(census_employee.renewal_benefit_group_enrollments.first.class).to eq HbxEnrollment
    end
  end

  context '.past_enrollments' do
    include_context "setup renewal application"

    before do
      benefit_application.expire!
    end

    let(:census_employee) do
      ce = FactoryBot.create(
        :benefit_sponsors_census_employee,
        employer_profile: employer_profile,
        benefit_sponsorship: benefit_sponsorship,
        dob: TimeKeeper.date_of_record - 30.years
      )

      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: ce, is_active: false)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let(:past_benefit_group_assignment) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_application.benefit_packages.first, census_employee: census_employee, is_active: false) }

    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_selected"
      )
    end

    let!(:terminated_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        family: census_employee.employee_role.person.primary_family,
        coverage_kind: "health",
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        terminated_on: TimeKeeper.date_of_record.prev_day,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_terminated"
      )
    end

    let!(:past_expired_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        kind: "employer_sponsored",
        family: census_employee.employee_role.person.primary_family,
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: past_benefit_group_assignment.id,
        aasm_state: "coverage_expired"
      )
    end

    let!(:canceled_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_canceled"
      )
    end
    let!(:canceled_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        household: census_employee.employee_role.person.primary_family.active_household,
        coverage_kind: "health",
        family: census_employee.employee_role.person.primary_family,
        kind: "employer_sponsored",
        benefit_sponsorship_id: benefit_sponsorship.id,
        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
        employee_role_id: census_employee.employee_role.id,
        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
        aasm_state: "coverage_canceled"
      )
    end
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    # https://github.com/health-connector/enroll/pull/1666/files
    # original commit removes this from scope
    xit 'should return past expired enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(past_expired_enrollment)).to eq true
    end

    it 'should display terminated enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(terminated_enrollment)).to eq true
    end

    it 'should NOT return current active enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(enrollment)).to eq false
    end

    it 'should NOT return canceled enrollment' do
      expect(census_employee.past_enrollments.to_a.include?(canceled_enrollment)).to eq false
    end
  end

  context 'editing a CensusEmployee SSN/DOB that is in a linked status' do

    let(:census_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship
    end

    let(:person) {FactoryBot.create(:person)}

    let(:user) {double("user")}
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, employer_profile: organization.employer_profile)}


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

    let(:census_employee) do
      FactoryBot.build :benefit_sponsors_census_employee,
                       employer_profile: employer_profile,
                       benefit_sponsorship: organization.active_benefit_sponsorship
    end

    it "should fail" do
      census_employee.dob = TimeKeeper.date_of_record - 30.years
      census_employee.hired_on = TimeKeeper.date_of_record - 31.years
      expect(census_employee.save).to be_falsey
      expect(census_employee.errors[:hired_on].any?).to be_truthy
      expect(census_employee.errors[:hired_on].to_s).to match /date can't be before  date of birth/
    end
  end

  context "expected to enroll" do

    let!(:valid_waived_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'waive'
    end

    let!(:enrolling_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'enroll'
    end

    let!(:invalid_waive) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship,
                        expected_selection: 'will_not_participate'
    end

    it "returns true for enrolling employees" do
      expect(enrolling_employee.expected_to_enroll?).to be_truthy
    end

    it "returns false for non enrolling employees" do
      expect(valid_waived_employee.expected_to_enroll?).to be_falsey
      expect(invalid_waive.expected_to_enroll?).to be_falsey
    end

    it "counts waived and enrollees when considering group size" do
      expect(valid_waived_employee.expected_to_enroll_or_valid_waive?).to be_truthy
      expect(enrolling_employee.expected_to_enroll_or_valid_waive?).to be_truthy
      expect(invalid_waive.expected_to_enroll_or_valid_waive?).to be_falsey
    end
  end

  context "when active employeees opt to waive" do

    let(:census_employee) do
      FactoryBot.build :benefit_sponsors_census_employee,
                       employer_profile: employer_profile,
                       benefit_sponsorship: organization.active_benefit_sponsorship,
                       benefit_group_assignments: [benefit_group_assignment]
    end
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, aasm_state: "coverage_waived")}

    it "returns true when employees waive the coverage" do
      expect(census_employee.waived?).to be_truthy
    end
    it "returns false for employees who are enrolling" do
      benefit_group_assignment.aasm_state = "coverage_selected"
      expect(census_employee.waived?).to be_falsey
    end
  end

  context "when active employeees has renewal benifit group" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      benefit_group_assignment.update_attribute(:updated_at, benefit_group_assignment.updated_at + 1.day)
      benefit_group_assignment.plan_year.update_attribute(:aasm_state, "renewing_enrolled")
    end

    it "returns true when employees waive the coverage" do
      expect(census_employee.waived?).to be_falsey
    end
    it "returns false for employees who are enrolling" do
      benefit_group_assignment.aasm_state = "coverage_waived"
      expect(census_employee.waived?).to be_truthy
    end
  end

  context '.renewal_benefit_group_assignment' do
    include_context "setup renewal application"

    let(:renewal_benefit_group) { renewal_application.benefit_packages.first}
    let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:benefit_group_assignment_two) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee)}


    it "should select the latest renewal benefit group assignment" do
      benefit_group_assignment_two.update_attribute(:updated_at, benefit_group_assignment_two.updated_at + 1.day)
      expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_two
    end

    context 'when multiple renewal assignments present' do

      context 'and latest assignment has enrollment associated' do
        let(:benefit_group_assignment_three) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee)}
        let(:enrollment) { double }

        before do
          allow(benefit_group_assignment_three).to receive(:hbx_enrollment).and_return(enrollment)
        end

        it 'should return assignment with coverage associated' do
          expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_three
        end
      end

      context 'and ealier assignment has enrollment associated' do
        let(:benefit_group_assignment_three) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee)}
        let(:enrollment) { double }

        before do
          allow(benefit_group_assignment_two).to receive(:hbx_enrollment).and_return(enrollment)
        end

        it 'should return assignment with coverage associated' do
          expect(census_employee.renewal_benefit_group_assignment).to eq benefit_group_assignment_two
        end
      end
    end
  end

  context ".is_waived_under?" do
    let(:census_employee) {CensusEmployee.new(**valid_params)}
    let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    before do
      family = FactoryBot.create(:family, :with_primary_family_member)
      allow(census_employee).to receive(:family).and_return(family)
      enrollment = FactoryBot.create(
        :hbx_enrollment, family: family,
                         household: family.active_household,
                         benefit_group_assignment: census_employee.benefit_group_assignments.first,
                         sponsored_benefit_package_id: census_employee.benefit_group_assignments.first.benefit_package.id
      )
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(enrollment)
    end

    context "for initial application" do

      it "should return true when employees waive the coverage" do
        benefit_group_assignment.hbx_enrollment.aasm_state = "inactive"
        benefit_group_assignment.hbx_enrollment.save
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_truthy
      end

      it "should return false for employees who are enrolling" do
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_falsey
      end
    end

    context "when active employeees has renewal benifit group" do

      before do
        benefit_group_assignment.benefit_application.update_attribute(:aasm_state, "renewing_enrolled")
      end

      it "should return false when employees who are enrolling" do
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_falsey
      end

      it "should return true for employees waive the coverage" do
        benefit_group_assignment.hbx_enrollment.aasm_state = "renewing_waived"
        benefit_group_assignment.hbx_enrollment.save
        expect(census_employee.is_waived_under?(benefit_group_assignment.benefit_application)).to be_truthy
      end
    end
  end

  context "and congressional newly designated employees are added" do
    let(:employer_profile_congressional) {employer_profile}
    let(:plan_year) {benefit_application}
    let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group, census_employee: civil_servant)}
    let(:civil_servant) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile_congressional, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:initial_state) {"eligible"}
    let(:eligible_state) {"newly_designated_eligible"}
    let(:linked_state) {"newly_designated_linked"}
    let(:employee_linked_state) {"employee_role_linked"}

    specify {expect(civil_servant.aasm_state).to eq initial_state}

    it "should transition to newly designated eligible state" do
      expect {civil_servant.newly_designate!}.to change(civil_servant, :aasm_state).to eq eligible_state
    end

    context "and the census employee is associated with an employee role" do
      before do
        civil_servant.benefit_group_assignments = [benefit_group_assignment]
        civil_servant.newly_designate
      end

      it "should transition to newly designated linked state" do
        expect {civil_servant.link_employee_role!}.to change(civil_servant, :aasm_state).to eq linked_state
      end

      context "and the link to employee role is removed" do
        before do
          civil_servant.benefit_group_assignments = [benefit_group_assignment]
          civil_servant.aasm_state = linked_state
          civil_servant.save!
        end

        it "should revert to 'newly designated eligible' state" do
          expect {civil_servant.delink_employee_role!}.to change(civil_servant, :aasm_state).to eq eligible_state
        end
      end
    end

    context "and multiple newly designated employees are present in database" do
      let(:second_civil_servant) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile_congressional, benefit_sponsorship: organization.active_benefit_sponsorship)}

      before do
        civil_servant.benefit_group_assignments = [benefit_group_assignment]
        civil_servant.newly_designate!

        second_civil_servant.benefit_group_assignments = [benefit_group_assignment]
        second_civil_servant.save!
        second_civil_servant.newly_designate!
        second_civil_servant.link_employee_role!
      end

      it "the scope should find them all" do
        expect(CensusEmployee.newly_designated.size).to eq 2
      end

      it "the scope should find the eligible census employees" do
        expect(CensusEmployee.eligible.size).to eq 1
      end

      it "the scope should find the linked census employees" do
        expect(CensusEmployee.linked.size).to eq 1
      end

      context "and new plan year begins, ending 'newly designated' status" do
        let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
        # before do
        #   benefit_application.update_attributes(aasm_state: :enrollment_closed)
        #   TimeKeeper.set_date_of_record_unprotected!(Date.today.end_of_year)
        #   TimeKeeper.set_date_of_record(Date.today.end_of_year + 1.day)
        # end

        xit "should transition 'newly designated eligible' status to initial state" do
          expect(civil_servant.aasm_state).to eq eligible_state
        end

        xit "should transition 'newly designated linked' status to linked state" do
          expect(second_civil_servant.aasm_state).to eq employee_linked_state
        end
      end

    end


  end

  describe "#trigger_notice" do
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship)}
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, :census_employee => census_employee)}
    it "should trigger job in queue" do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
      census_employee.trigger_notice("ee_sep_request_accepted_notice")
      queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
        job_info[:job] == ShopNoticesNotifierJob
      end
      expect(queued_job[:args]).to eq [census_employee.id.to_s, 'ee_sep_request_accepted_notice']
    end
  end

  describe "search_hash" do
    context 'census search query' do

      it "query string for census employee firstname or last name" do
        employee_search = "test1"
        expected_result = {"$or" => [{"$or" => [{"first_name" => /test1/i}, {"last_name" => /test1/i}]}, {"encrypted_ssn" => "+MZq0qWj9VdyUd9MifJWpQ==\n"}]}
        result = CensusEmployee.search_hash(employee_search)
        expect(result).to eq expected_result
      end

      it "census employee query string for full name" do
        employee_search = "test1 test2"
        expected_result = {"$or" => [{"$and" => [{"first_name" => /test1|test2/i}, {"last_name" => /test1|test2/i}]}, {"encrypted_ssn" => "0m50gjJW7mR4HLnepJyFmg==\n"}]}
        result = CensusEmployee.search_hash(employee_search)
        expect(result).to eq expected_result
      end

    end
  end

  describe "#has_no_hbx_enrollments?" do
    let(:census_employee) do
      FactoryBot.create :census_employee_with_active_assignment,
                        employer_profile: employer_profile,
                        benefit_sponsorship: organization.active_benefit_sponsorship
    end

    it "should return true if no employee role linked" do
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return true if employee role present & no enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return true if employee role present & no active enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollment).and_return double("HbxEnrollment", aasm_state: "coverage_canceled")
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq true
    end

    it "should return false if employee role present & active enrollment present" do
      allow(census_employee).to receive(:employee_role).and_return double("EmployeeRole")
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollment).and_return double("HbxEnrollment", aasm_state: "coverage_selected")
      expect(census_employee.send(:has_no_hbx_enrollments?)).to eq false
    end
  end

  describe "#benefit_package_for_date", dbclean: :around_each do
    let(:employer_profile) {abc_profile}
    let(:census_employee) do
      FactoryBot.create :benefit_sponsors_census_employee,
                        employer_profile: employer_profile,
                        benefit_sponsorship: benefit_sponsorship
    end

    before do
      census_employee.save
    end

    context "when ER has imported applications" do

      it "should return nil if given effective_on date is in imported benefit application" do
        initial_application.update_attributes(aasm_state: :imported)
        coverage_date = initial_application.end_on - 1.month
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq nil
      end

      it "should return nil if given coverage_date is not between the bga start_on and end_on dates" do
        initial_application.update_attributes(aasm_state: :imported)
        coverage_date = census_employee.benefit_group_assignments.first.start_on - 1.month
        expect(census_employee.benefit_group_assignment_for_date(coverage_date)).to eq nil
      end

      it "should return latest bga for given coverage_date" do
        bga = census_employee.benefit_group_assignments.first
        coverage_date = bga.start_on
        bga.update_attributes(is_active: false)
        bga1 = bga.dup
        bga.update_attributes(created_at: bga.created_at - 1.day)
        census_employee.benefit_group_assignments << bga1
        expect(census_employee.benefit_group_assignment_for_date(coverage_date)).to eq bga1
      end
    end

    context "when ER has active and renewal benefit applications" do

      include_context "setup renewal application"

      let(:benefit_group_assignment_two) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: census_employee)}

      it "should return active benefit_package if given effective_on date is in active benefit application" do
        coverage_date = initial_application.end_on - 1.month
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq renewal_application.benefit_packages.first
      end

      it "should return renewal benefit_package if given effective_on date is in renewal benefit application" do
        census_employee.active_benefit_group_assignment.update_attributes!(is_active: false)
        census_employee.inactive_benefit_group_assignments.first.benefit_package.update_attributes!(is_active: false)
        benefit_group_assignment_two
        coverage_date = renewal_application.start_on
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq renewal_application.benefit_packages.first
      end
    end

    context "when ER has imported, mid year conversion and renewal benefit applications" do

      let(:organization) do
        FactoryBot.build(:benefit_sponsors_organizations_general_organization,
                         :with_aca_shop_cca_employer_profile_imported_and_renewal_application,
                         site: site)
      end

      let(:myc_application) do
        FactoryBot.build(:benefit_sponsors_benefit_application,
                         :with_benefit_package,
                         benefit_sponsorship: benefit_sponsorship,
                         aasm_state: :active,
                         default_effective_period: ((benefit_application.end_on - 2.months).next_day..benefit_application.end_on),
                         default_open_enrollment_period: ((benefit_application.end_on - 1.year).next_day - 1.month..(benefit_application.end_on - 1.year).next_day - 15.days))
      end

      let(:mid_year_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: myc_application.benefit_packages.first, census_employee: census_employee)}

      before do
        benefit_sponsorship.benefit_applications << myc_application
        benefit_sponsorship.save
      end

      it "should return mid year benefit_package if given effective_on date is in both imported & mid year benefit application" do
        coverage_date = myc_application.start_on
        mid_year_benefit_group_assignment
        census_employee.benefit_group_assignments.where(:benefit_package_id.in => benefit_application.benefit_packages.map(&:id)).each do |bga|
          # when there is both MYC & Imported Plan years, is_active for imported plan year's bga's should be false
          # to allow plan shop through myc plan years
          bga.update_attributes!(is_active: false)
          bga.benefit_package.update_attributes!(is_active: false)
        end
        expect(census_employee.benefit_package_for_date(coverage_date)).to eq myc_application.benefit_packages.first
      end
    end
  end

  describe "#is_cobra_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_linked"}

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"employee_termination_pending"}

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq true
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"employment_terminated"}

      before do
        allow(census_employee).to receive(:employment_terminated_on).and_return TimeKeeper.date_of_record.last_month
      end

      it "should return false" do
        expect(census_employee.is_cobra_possible?).to eq true
      end
    end
  end

  describe "#is_rehired_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_eligible"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"rehired"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_terminated"}

      it "should return false" do
        expect(census_employee.is_rehired_possible?).to eq true
      end
    end
  end

  describe "#is_terminate_possible" do
    let(:params) { valid_params.merge(:aasm_state => aasm_state) }
    let(:census_employee) { CensusEmployee.new(**params) }

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"employment_terminated"}

      it "should return false" do
        expect(census_employee.is_terminate_possible?).to eq true
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"eligible"}

      it "should return false" do
        expect(census_employee.is_terminate_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_eligible"}

      it "should return false" do
        expect(census_employee.is_terminate_possible?).to eq false
      end
    end

    context "if censue employee is cobra linked" do
      let(:aasm_state) {"cobra_linked"}

      it "should return false" do
        expect(census_employee.is_terminate_possible?).to eq false
      end
    end

    context "if censue employee is newly designatede linked" do
      let(:aasm_state) {"newly_designated_linked"}

      it "should return false" do
        expect(census_employee.is_terminate_possible?).to eq false
      end
    end
  end

  describe "#terminate_employee_enrollments" do

    include_context "setup renewal application"

    let(:renewal_effective_date) { Date.new(2020,3,1) }
    let(:predecessor_state) { :expired }
    let(:renewal_state) { :active }
    let(:renewal_benefit_group) { renewal_application.benefit_packages.first}
    let(:census_employee) do
      ce = FactoryBot.create(
          :benefit_sponsors_census_employee,
          employer_profile: employer_profile,
          benefit_sponsorship: organization.active_benefit_sponsorship
      )
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.build(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      ce
    end

    let!(:active_bga) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee, is_active: true) }
    let!(:inactive_bga) { FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: current_benefit_package, census_employee: census_employee, is_active: false) }

    let!(:active_enrollment) do
      FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "health",
          kind: "employer_sponsored",
          effective_on: renewal_benefit_group.start_on,
          family: census_employee.employee_role.person.primary_family,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: renewal_benefit_group.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: active_bga.id,
          aasm_state: "coverage_selected"
      )
    end

    let!(:expired_enrollment) do
      FactoryBot.create(
          :hbx_enrollment,
          household: census_employee.employee_role.person.primary_family.active_household,
          coverage_kind: "health",
          kind: "employer_sponsored",
          effective_on: current_benefit_package.start_on,
          family: census_employee.employee_role.person.primary_family,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: current_benefit_package.id,
          employee_role_id: census_employee.employee_role.id,
          benefit_group_assignment_id: inactive_bga.id,
          aasm_state: "coverage_expired"
      )
    end

    context "when EE termination date falls under expired application" do
      let!(:date) { benefit_sponsorship.benefit_applications.expired.first.effective_period.max }
      before do
        census_employee.employment_terminated_on = date - 15.days
        census_employee.coverage_terminated_on = date
        census_employee.aasm_state = "employment_terminated"
        census_employee.benefit_group_assignments.where(is_active: false).first.end_on = date
        census_employee.save
        census_employee.terminate_employee_enrollments
        expired_enrollment.reload
        active_enrollment.reload
      end

      it "should termiante, expired enrollment with terminated date = ee coverage termination date" do
        expect(expired_enrollment.aasm_state).to eq "coverage_terminated"
        expect(expired_enrollment.terminated_on).to eq date
      end

      it "should cancel active coverage" do
        expect(active_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end

    context "when EE termination date falls under active application" do
      before do
        census_employee.employment_terminated_on = TimeKeeper.date_of_record.end_of_month
        census_employee.coverage_terminated_on = TimeKeeper.date_of_record.end_of_month
        census_employee.aasm_state = "employment_terminated"
        census_employee.save
        census_employee.terminate_employee_enrollments
        expired_enrollment.reload
        active_enrollment.reload
      end

      it "shouldn't update expired enrollment" do
        expect(expired_enrollment.aasm_state).to eq "coverage_expired"
      end

      it "should termiante active coverage" do
        expect(active_enrollment.aasm_state).to eq "coverage_termination_pending"
      end

      it "should cancel future active coverage" do
        active_enrollment.effective_on = TimeKeeper.date_of_record.next_month
        active_enrollment.save
        census_employee.terminate_employee_enrollments
        active_enrollment.reload
        expect(active_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
