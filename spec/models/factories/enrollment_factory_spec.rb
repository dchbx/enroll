require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Factories::EnrollmentFactory, :dbclean => :after_each do
  def p(model)
    model.class.find(model.id)
  end

  let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  context "starting with unlinked employee_family and employee_role" do
    let(:hired_on) { TimeKeeper.date_of_record - 30.days }
    let(:terminated_on) { TimeKeeper.date_of_record - 1.days }
    let(:dob) { employee_role.dob }
    let(:ssn) { employee_role.ssn }

    let!(:census_employee) do
      create(:census_employee,
             hired_on: hired_on,
             employment_terminated_on: terminated_on,
             dob: dob, ssn: ssn,
             benefit_sponsorship: benefit_sponsorship,
             employer_profile: benefit_sponsorship.profile,
             benefit_group: current_benefit_package)
    end
    let(:employee_role) {FactoryBot.build(:employee_role, employer_profile: abc_profile)}

    describe "After performing the link", :dbclean => :after_each do

      before(:each) do
        Factories::EnrollmentFactory.link_census_employee(census_employee, employee_role, abc_profile)
      end

      it "should set employee role id on the census employee" do
        expect(census_employee.employee_role_id).to eq employee_role.id
      end

      it "should set employer profile id on the employee_role" do
        expect(employee_role.benefit_sponsors_employer_profile_id).to eq abc_profile.id
      end

      it "should set census employee id on the employee_role" do
        expect(employee_role.census_employee_id).to eq census_employee.id
      end

      it "should set hired on on the employee_role" do
        expect(employee_role.hired_on).to eq hired_on
      end

      it "should set terminated on on the employee_role" do
        expect(employee_role.terminated_on).to eq terminated_on
      end
    end
  end

  context "dual role contact methods" do
    let(:existing_person) {FactoryBot.create(:person, :with_consumer_role)}

    let(:employer_profile) { abc_profile }
    let(:organization) { abc_organization }
    let(:hired_on) {TimeKeeper.date_of_record.beginning_of_month}
    let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, ssn: existing_person.ssn, dob: existing_person.dob, hired_on: hired_on, benefit_sponsorship: organization.active_benefit_sponsorship)}

    describe "existing consumer role adds employee role" do
      context 'build_employee_role' do
        before do
          existing_person.consumer_role.update_attributes(contact_method: "Paper Only")
          Factories::EnrollmentFactory.build_employee_role(existing_person, nil, employer_profile,census_employee, hired_on)
        end

        it 'should set new_census_employee to employee_role' do
          expect(census_employee.employee_role.new_census_employee).to eq(census_employee)
        end

        it 'should give employee_role the same contact method as consumer_role' do
          expect(existing_person.employee_roles.first.contact_method).to eq(existing_person.consumer_role.contact_method)
        end
      end

      context 'should not build_employee_role' do
        before do
          existing_person.unset(:gender)
          Factories::EnrollmentFactory.build_employee_role(existing_person, nil, employer_profile,census_employee, hired_on)
        end

        it 'should not have a employee_role' do
          expect(census_employee.employee_role).to be_nil
        end
      end

      context 'should build_employee_role with active dependents' do
        let(:family)  {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: existing_person)}
        let(:dependent2) {family.family_members.last}

        before do
          allow(existing_person).to receive("primary_family").and_return(family)
          allow(existing_person).to receive(:families).and_return([family])
          dependent2.update_attributes!(is_active: false)
          Factories::EnrollmentFactory.build_employee_role(existing_person, nil, employer_profile,census_employee, hired_on)
        end

        it 'should not turn a non_active dependent to active' do
          expect(dependent2.is_active?).to eq false
        end
      end
    end

    describe "add consumer role to existing employee role" do
      let(:existing_person2) {FactoryBot.create(:person, :with_employee_role)}

      before do
        allow(existing_person2).to receive(:active_employee_roles).and_return(existing_person2.employee_roles)
        allow(existing_person2).to receive(:has_active_employee_role?).and_return(true)
        existing_person2.employee_roles.first.update_attributes(:contact_method => 'Paper Only')
      end

      it "adds contact method for new consumer role to match employee role contact method" do
        consumer_role = Factories::EnrollmentFactory.build_consumer_role(existing_person2, nil)
        expect(consumer_role.contact_method).to eq(existing_person2.employee_roles.first.contact_method)
      end
    end
  end
end

RSpec.describe Factories::EnrollmentFactory, :dbclean => :after_each do
  let(:employer_profile_without_family) {FactoryBot.create(:employer_profile)}
  let(:employer_profile) {FactoryBot.create(:employer_profile)}
  let(:plan_year) {FactoryBot.create(:plan_year, employer_profile: employer_profile)}
  let(:benefit_group) {FactoryBot.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group, :start_on => plan_year.start_on, is_active: true)}
  let(:census_employee) {FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id, benefit_group_assignments: [benefit_group_assignment])}
  let(:user) {FactoryBot.create(:user)}
  let(:first_name) {census_employee.first_name}
  let(:last_name) {census_employee.last_name}
  let(:ssn) {census_employee.ssn}
  let(:dob) {census_employee.dob}
  let(:gender) {census_employee.gender}
  let(:hired_on) {census_employee.hired_on}

  let(:valid_person_params) do
    {
      user: user,
      first_name: first_name,
      last_name: last_name,
    }
  end
  let(:valid_employee_params) do
    {
      ssn: ssn,
      gender: gender,
      dob: dob,
      hired_on: hired_on
      # contact_method: "Paper Only"
    }
  end
  let(:valid_params) do
    {employer_profile: employer_profile}.merge(valid_person_params).merge(valid_employee_params)
  end

  context "an employer profile exists with an employee and dependents in the census and a published plan year" do
    let(:census_dependent){FactoryBot.build(:census_dependent)}
    let(:primary_applicant) {@family.primary_applicant}
    let(:params) {valid_params}

    before do
      census_employee.census_dependents = [census_dependent]
      census_employee.save
      plan_year.update_attributes({:aasm_state => 'published'})
    end

    # TODO add_employee_role method in enrollment factory didn't updated as part of new model,
    # marking spec as pending update when we update add_employee_role method.
    xcontext "and no prior person exists" do
      before do
        @user = FactoryBot.create(:user)
        # employer_profile = FactoryBot.create(:employer_profile)
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        valid_employee_params = {
          ssn: census_employee.ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(
          valid_person_params
        ).merge(valid_employee_params)
        params = valid_params
        @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
        @primary_applicant = @family.primary_applicant
      end

      it "should have a family" do
        expect(@family).to be_a Family
      end

      it "should be the primary applicant" do
        expect(@employee_role.person).to eq @primary_applicant.person
      end

      it "should have linked the family" do
        expect(CensusEmployee.find(census_employee.id).employee_role).to eq @employee_role
      end

      it "should have all family_members" do
        expect(@family.family_members.count).to eq (census_employee.census_dependents.count + 1)
      end

      it "should set a home email" do
        email = @employee_role.person.emails.first
        expect(email.address).to eq @user.email
        expect(email.kind).to eq "home"
      end

      it "should transfer the census_employee address to the person" do
        expect(@employee_role.person.home_address).to eq census_employee.address
      end
    end

    # TODO add_employee_role method in enrollment factory didn't updated as part of new model,
    # marking spec as pending update when we update add_employee_role method.

    xcontext "and a prior person exists but is not associated with the user" do
      before(:each) do
        @user = FactoryBot.create(:user)
        census_dependent = FactoryBot.build(:census_dependent)
        benefit_group = FactoryBot.create(:benefit_group)
        plan_year = benefit_group.plan_year
        employer_profile = plan_year.employer_profile
        census_employee = FactoryBot.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group)])
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        valid_employee_params = {
          ssn: census_employee.ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
        params = valid_params
        @person = FactoryBot.create(:person,
                                     valid_person_params.except(:user).merge(dob: census_employee.dob,
                                                                             ssn: census_employee.ssn))
        @person.addresses << FactoryBot.create(:address, person: @person)
        plan_year.update_attributes({:aasm_state => 'published'})
        @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
      end

      it "should link the user to the person" do
        expect(@employee_role.person.user).to eq @user
      end

      it "should link the person to the user" do
        expect(@user.person).to eq @person
      end

      it "should add the employee role to the user" do
        expect(@user.roles).to include "employee"
      end

      it "should link the employee role" do
        expect(@employee_role.census_employee.employee_role_linked?).to be_truthy
      end

      it "should leave the original address on the person" do
        expect(@employee_role.person.home_address).to eq @person.home_address
      end
    end

    # TODO add_employee_role method in enrollment factory didn't updated as part of new model,
    # marking spec as pending update when we update add_employee_role method.
    xcontext "and a prior person exists with an existing policy but is not associated with a user" do
      before(:each) do
        @user = FactoryBot.create(:user)
        benefit_group = FactoryBot.create(:benefit_group)
        plan_year = benefit_group.plan_year
        employer_profile = plan_year.employer_profile
        benefit_group_assignment = FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group)
        census_employee = FactoryBot.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment])
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
          gender: census_employee.gender,
        }
        valid_employee_params = {
          ssn: census_employee.ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
        params = valid_params
        @person = FactoryBot.create(:person,
                                     valid_person_params.except(:user).merge(dob: census_employee.dob,
                                                                             ssn: census_employee.ssn))

        @family = Family.new.build_from_person(@person)
        @family.person_id = @person.id
        @hbx_enrollment = FactoryBot.create(:hbx_enrollment, household: @family.active_household, benefit_group: benefit_group, benefit_group_assignment: benefit_group_assignment)
        plan_year.update_attributes({:aasm_state => 'published'})
        benefit_group_assignment.hbx_enrollment = @hbx_enrollment
        benefit_group_assignment.select_coverage!
        @employee_role, @family2 = Factories::EnrollmentFactory.add_employee_role(**params)
      end

      it "should link the user to the person" do
        expect(@employee_role.person.user).to eq @user
      end

      it "should link the person to the user" do
        expect(@user.person).to eq @person
      end

      it "should add the employee role to the user" do
        expect(@user.roles).to include "employee"
      end

      it "should link the employee role" do
        expect(@employee_role.census_employee.employee_role_linked?).to be_truthy
      end

      it "should have a valid census employee on the employee role" do
        expect(@employee_role.census_employee.valid?).to be_truthy
      end
    end

    # TODO add_employee_role method in enrollment factory didn't updated as part of new model,
    # marking spec as pending update when we update add_employee_role method.
    xcontext "and another employer profile exists with the same employee and dependents in the census"  do
      before do
        @user = FactoryBot.create(:user)
        employer_profile = FactoryBot.create(:employer_profile)
        plan_year = FactoryBot.create(:plan_year, employer_profile: employer_profile)
        benefit_group = FactoryBot.create(:benefit_group, plan_year: plan_year)
        plan_year.benefit_groups = [benefit_group]
        plan_year.save

        census_dependent = FactoryBot.build(:census_dependent)
        census_employee = FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id,
                                              census_dependents: [census_dependent])
        benefit_group_assignment = FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)
        census_employee.benefit_group_assignments = [benefit_group_assignment]
        census_employee.save

        plan_year.update_attributes({:aasm_state => 'published'})

        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        @ssn = census_employee.ssn
        @dob = census_employee.dob
        valid_employee_params = {
          ssn: @ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
        @first_employee_role, @first_family = Factories::EnrollmentFactory.add_employee_role(**valid_params)

        dependents = census_employee.census_dependents.collect(&:dup)
        employee = census_employee.dup


        employer_profile_2 = FactoryBot.create(:employer_profile)
        plan_year_2 = FactoryBot.create(:plan_year, employer_profile: employer_profile_2)
        benefit_group_2 = FactoryBot.create(:benefit_group, plan_year: plan_year_2)
        plan_year_2.benefit_groups = [benefit_group_2]
        plan_year_2.save

        census_dependent_2 = census_dependent.dup
        census_employee_2 = census_employee.dup
        census_employee_2.employer_profile_id = employer_profile_2.id
        census_employee_2.census_dependents = [census_dependent_2]
        benefit_group_assignment_2 = FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group_2, :start_on => plan_year_2.start_on, is_active: true)
        census_employee_2.benefit_group_assignments = [benefit_group_assignment_2]
        census_employee_2.save

        plan_year_2.update_attributes({:aasm_state => 'published'})

        @second_params = { employer_profile: employer_profile_2 }.merge(valid_person_params).merge(valid_employee_params)
        @second_employee_role, @second_census_employee = Factories::EnrollmentFactory.add_employee_role(**@second_params)
      end

      it "should still have a findable person" do
        people = Person.match_by_id_info(ssn: @ssn, dob: @dob)
        expect(people.count).to eq 1
        expect(people.first).to be_a Person
      end

      it "second employee role should be saved" do
        expect(@second_employee_role.persisted?).to be
      end

      it "second family should be saved" do
        expect(@second_census_employee.persisted?).to be
      end

      it "second employee role should be valid" do
        expect(@second_employee_role.valid?).to be
      end

      it "second family should be the first family" do
        expect(@second_census_employee).to eq @first_family
      end
    end
  end

  # TODO add_employee_role method in enrollment factory didn't updated as part of new model,
  # marking spec as pending update when we update add_employee_role method.
  xdescribe ".add_employee_role" do
    context "when the employee already exists but is not linked" do
      let(:census_dependent){FactoryBot.build(:census_dependent)}
      let(:census_employee) {FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id,
        census_dependents: [census_dependent],
        )}
      let(:existing_person) {FactoryBot.create(:person, valid_person_params)}
      let(:employee) {FactoryBot.create(:employee_role, valid_employee_params.merge(person: existing_person, employer_profile: employer_profile))}
      before {user;census_employee;employee}

      context "with all required data" do
        let(:params) {valid_params}
        let(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}
        let(:params) {valid_params}

        before do
          plan_year.benefit_groups = [benefit_group]
          plan_year.save
          census_employee.benefit_group_assignments = [benefit_group_assignment]
          census_employee.save
          PlanYear.find(plan_year.id).update_attributes({:aasm_state => 'published'})
        end

        it "should not raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end

        context "successfully created" do
          let(:primary_applicant) {family.primary_applicant}
          let(:employer_census_families) do
            EmployerProfile.find(employer_profile.id.to_s).employee_families
          end
          before {@employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)}

          it "should return the existing employee" do
            expect(@employee_role.id.to_s).to eq employee.id.to_s
          end

          it "should return a family" do
            expect(@family).to be_a Family
          end
        end
      end
    end

    context "census_employee params" do
      # let(:benefit_group_assignment){FactoryBot.build(:benefit_group_assignment)}
      let(:census_dependent){FactoryBot.build(:census_dependent)}
      let(:census_employee) {FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id,
              census_dependents: [census_dependent],
              # benefit_group_assignments: [benefit_group_assignment]
              )}
      context "with no arguments" do
        let(:params) {{}}

        it "should raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no user' do
        let(:params) {valid_params.except(:user)}
        let(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}

        before do
          plan_year.benefit_groups = [benefit_group]
          plan_year.save
          census_employee.benefit_group_assignments = [benefit_group_assignment]
          census_employee.save
          PlanYear.find(plan_year.id).update_attributes({:aasm_state => 'published'})
        end

        it 'should not raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end
      end

      context 'with no employer_profile' do
        let(:params) {valid_params.except(:employer_profile)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no first_name' do
        let(:params) {valid_params.except(:first_name)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no last_name' do
        let(:params) {valid_params.except(:last_name)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no ssn' do
        let(:params) {valid_params.except(:ssn)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no gender' do
        let(:params) {valid_params.except(:gender)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no dob' do
        let(:params) {valid_params.except(:dob)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no hired_on' do
        let(:params) {valid_params.except(:hired_on)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context "with all required data, but employer_profile has no families" do
        let(:params) {valid_params.merge(employer_profile: employer_profile_without_family)}

        it "should raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context "with all required data" do
        let(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryBot.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}
        let(:params) {valid_params}
        let(:family1) { Family.new }

        before do
          plan_year.benefit_groups = [benefit_group]
          plan_year.save
          census_employee.benefit_group_assignments = [benefit_group_assignment]
          census_employee.save
          PlanYear.find(plan_year.id).update_attributes({:aasm_state => 'published'})
        end

        it "should not raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end

        context "successfully created" do
          let(:primary_applicant) {@family.primary_applicant}

          before do
            @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
          end

          it "should have a family" do
            expect(@family).to be_a Family
          end

          it "should be the primary applicant" do
            expect(@employee_role.person).to eq primary_applicant.person
          end

          it "should have linked the family" do
            expect(CensusEmployee.find(census_employee.id).employee_role).to eq @employee_role
          end

          it "should have work email" do
            expect(@employee_role.person.work_email.address).to eq @employee_role.census_employee.email_address
          end
        end

        it "build_employee_role should call save_relevant_coverage_households" do
          allow(Family).to receive(:new).and_return family1
          expect(family1).to receive(:save_relevant_coverage_households)
          employee_role, family = Factories::EnrollmentFactory.add_employee_role(**params)
        end
      end
    end
  end

  # TODO Fix consumer role spec when we implement new model in DC.
  xdescribe ".add_consumer_role" do
    let(:is_incarcerated) {true}
    let(:is_applicant) {true}
    let(:is_state_resident) {true}
    let(:citizen_status) {"us_citizen"}
    let(:valid_person) {FactoryBot.create(:person)}

    let(:valid_params) do
      { person: valid_person,
        new_is_incarcerated: is_incarcerated,
        new_is_applicant: is_applicant,
        new_is_state_resident: is_state_resident,
        new_ssn: ssn,
        new_dob: dob,
        new_gender: gender,
        new_citizen_status: citizen_status
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_incarcerated" do
      let(:params) {valid_params.except(:new_is_incarcerated)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_applicant" do
      let(:params) {valid_params.except(:new_is_applicant)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_state_resident" do
      let(:params) {valid_params.except(:new_is_state_resident)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no citizen_status" do
      let(:params) {valid_params.except(:new_citizen_status)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.not_to raise_error
      end
    end

  end


  describe ".add_broker_role" do
    let(:mailing_address) do
      {
        kind: 'home',
        address_1: 1111,
        address_2: 111,
        city: 'Washington',
        state: 'DC',
        zip: 11111
      }
    end

    let(:npn) {"xyz123xyz"}
    let(:broker_kind) {"broker"}
    let(:valid_params) do
      { person: valid_person,
        new_npn: npn,
        new_kind: broker_kind,
        new_mailing_address: mailing_address
      }
    end
    let(:valid_person) {FactoryBot.create(:person)}

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.not_to raise_error
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:new_npn)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:new_kind)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no mailing address" do
      let(:params) {valid_params.except(:new_mailing_address)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

  end
end

describe Factories::EnrollmentFactory, "with a freshly created consumer role" do
  context "with no errors" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml"))).first }
    let(:user) { FactoryBot.create(:user) }

    let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
    let(:person) { consumer_role.person }
    let(:ua_params) do
      {
        person: {
          "first_name" => primary.person.name_first,
          "last_name" => primary.person.name_last,
          "middle_name" => primary.person.name_middle,
          "name_pfx" => primary.person.name_pfx,
          "name_sfx" => primary.person.name_sfx,
          "dob" => primary.person_demographics.birth_date,
          "ssn" => primary.person_demographics.ssn,
          "no_ssn" => "",
          "gender" => primary.person_demographics.sex.split('#').last,
          "is_applying_coverage" => false,
          addresses: [],
          phones: [],
          emails: []
        }
      }
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params[:person], user) }
    let(:family) { consumer_role.person.primary_family }
    before :each do
      family.update_attributes!(:e_case_id => parser.integrated_case_id)
    end

    it "should not crash on updating the e_case_id" do
      expect {person.primary_family.update_attributes!(:e_case_id => "some e case id whatever")}.not_to raise_error
    end

    it "should is_applying_coverage should be false" do
      expect(person.consumer_role.is_applying_coverage).to eq false
    end

  end

  context "with errors initializing the person" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml"))).first }
    let(:user) { FactoryBot.create(:user) }

    let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
    let(:person) { consumer_role.person }
    let(:ua_params) do
      {
        person: {
          "first_name" => primary.person.name_first,
          "last_name" => primary.person.name_last,
          "middle_name" => primary.person.name_middle,
          "name_pfx" => primary.person.name_pfx,
          "name_sfx" => primary.person.name_sfx,
          "dob" => primary.person_demographics.birth_date,
          "ssn" => primary.person_demographics.ssn,
          "no_ssn" => "",
          "gender" => primary.person_demographics.sex.split('#').last,
          addresses: [],
          phones: [],
          emails: []
        }
      }
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params[:person], user) }
    let(:family) { consumer_role.person.primary_family }
    before :each do
      allow(Factories::EnrollmentFactory).to receive(:initialize_person).and_return([nil, nil])
    end

    it "should return nil for the consumer role" do
      expect(Factories::EnrollmentFactory.construct_consumer_role(ua_params[:person], user)).not_to be
    end
  end
end

describe Factories::EnrollmentFactory, "with an exisiting consumer role" do

  context ".build_family" do
    let(:subject) { Factories::EnrollmentFactory }
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}

    it "should add a family to a person without one" do
      subject.build_family(person,[])
      expect(person.primary_family).to be_truthy
    end

    it "should is_applying_coverage should be false" do
      expect(person.consumer_role.is_applying_coverage).to eq true
    end

  end

  context ".build_family with existing family" do
    let(:subject) { Factories::EnrollmentFactory }
    let(:person) { original_family.person}
    let(:original_family) { FactoryBot.create(:family, :with_primary_family_member) }

    it "should return primary family" do
      original_family = subject.build_family(person,[])
      expect(original_family).to eq(person.primary_family)
    end

  end


end
