require 'rails_helper'

describe Factories::EnrollmentFactory, "starting with unlinked employee_family and employee_role" do
  def p(model)
    model.class.find(model.id)
  end

  let(:hired_on) { Date.today - 30.days }
  let(:terminated_on) { Date.today - 1.days }
  let(:dob) { employee_role.dob }
  let(:ssn) { employee_role.ssn }

  let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let!(:plan_year) {
    FactoryGirl.create(:plan_year,
      employer_profile: employer_profile,
      aasm_state: "published"
    )
  }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
  let!(:census_employee) {
    FactoryGirl.create(:census_employee,
      hired_on: hired_on,
      employment_terminated_on: terminated_on,
      dob: dob,
      ssn: ssn,
      employer_profile: employer_profile
    )
  }
  let!(:benefit_group_assignment) {
    FactoryGirl.create(:benefit_group_assignment,
      benefit_group: benefit_group,
      census_employee: census_employee,
      start_on: TimeKeeper.date_of_record
    )
  }

  let!(:employee_role) {
    FactoryGirl.create(:employee_role, employer_profile: employer_profile)
  }

  describe "After performing the link" do

    before(:each) do
      Factories::EnrollmentFactory.link_census_employee(census_employee, employee_role, employer_profile)
      census_employee.save
      employee_role.save
      employer_profile.save
    end

    it "should set employee role id on the census employee" do
      expect(p(census_employee).employee_role_id).to eq employee_role.id
    end

    it "should set employer profile id on the employee_role" do
      expect(p(employee_role).employer_profile_id).to eq employer_profile.id
    end

    it "should set census employee id on the employee_role" do
      expect(p(employee_role).census_employee_id).to eq census_employee.id
    end

    it "should set hired on on the employee_role" do
      expect(p(employee_role).hired_on).to eq hired_on
    end

    it "should set terminated on on the employee_role" do
      expect(p(employee_role).terminated_on).to eq terminated_on
    end
  end
end

RSpec.describe Factories::EnrollmentFactory, :dbclean => :after_each do
  let(:employer_profile_without_family) {FactoryGirl.create(:employer_profile)}
  let(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
  let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, :start_on => plan_year.start_on, is_active: true)}
  let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, benefit_group_assignments: [benefit_group_assignment])}
  let(:user) {FactoryGirl.create(:user)}
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
    }
  end
  let(:valid_params) do
    {employer_profile: employer_profile}.merge(valid_person_params).merge(valid_employee_params)
  end

  context "an employer profile exists with an employee and dependents in the census and a published plan year" do
    let(:census_dependent){FactoryGirl.build(:census_dependent)}
    let(:primary_applicant) {@family.primary_applicant}
    let(:params) {valid_params}

    before do
      census_employee.census_dependents = [census_dependent]
      census_employee.save
      plan_year.update_attributes({:aasm_state => 'published'})
    end

    context "and no prior person exists" do
      before do
        @user = FactoryGirl.create(:user)
        # employer_profile = FactoryGirl.create(:employer_profile)
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

    context "and a prior person exists but is not associated with the user" do
      before(:each) do
        @user = FactoryGirl.create(:user)
        census_dependent = FactoryGirl.build(:census_dependent)
        benefit_group = FactoryGirl.create(:benefit_group)
        plan_year = benefit_group.plan_year
        employer_profile = plan_year.employer_profile
        census_employee = FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)])
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
        @person = FactoryGirl.create(:person,
                                     valid_person_params.except(:user).merge(dob: census_employee.dob,
                                                                             ssn: census_employee.ssn))
        @person.addresses << FactoryGirl.create(:address, person: @person)
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

    context "and a prior person exists with an existing policy but is not associated with a user" do
      before(:each) do
        @user = FactoryGirl.create(:user)
        benefit_group = FactoryGirl.create(:benefit_group)
        plan_year = benefit_group.plan_year
        employer_profile = plan_year.employer_profile
        benefit_group_assignment = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)
        census_employee = FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment])
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
        @person = FactoryGirl.create(:person,
                                     valid_person_params.except(:user).merge(dob: census_employee.dob,
                                                                             ssn: census_employee.ssn))

        @family = Family.new.build_from_person(@person)
        @family.person_id = @person.id
        @hbx_enrollment = FactoryGirl.create(:hbx_enrollment, household: @family.active_household, benefit_group: benefit_group, benefit_group_assignment: benefit_group_assignment)
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

    context "and another employer profile exists with the same employee and dependents in the census"  do
      before do
        @user = FactoryGirl.create(:user)
        employer_profile = FactoryGirl.create(:employer_profile)
        plan_year = FactoryGirl.create(:plan_year, employer_profile: employer_profile)
        benefit_group = FactoryGirl.create(:benefit_group, plan_year: plan_year)
        plan_year.benefit_groups = [benefit_group]
        plan_year.save

        census_dependent = FactoryGirl.build(:census_dependent)
        census_employee = FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
                                              census_dependents: [census_dependent])
        benefit_group_assignment = FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)
        census_employee.benefit_group_assignments = [benefit_group_assignment]
        census_employee.save

        plan_year.update_attributes({:aasm_state => 'published'})

        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        @ssn = census_employee.ssn
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


        employer_profile_2 = FactoryGirl.create(:employer_profile)
        plan_year_2 = FactoryGirl.create(:plan_year, employer_profile: employer_profile_2)
        benefit_group_2 = FactoryGirl.create(:benefit_group, plan_year: plan_year_2)
        plan_year_2.benefit_groups = [benefit_group_2]
        plan_year_2.save

        census_dependent_2 = census_dependent.dup
        census_employee_2 = census_employee.dup
        census_employee_2.employer_profile_id = employer_profile_2.id
        census_employee_2.census_dependents = [census_dependent_2]
        benefit_group_assignment_2 = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group_2, :start_on => plan_year_2.start_on, is_active: true)
        census_employee_2.benefit_group_assignments = [benefit_group_assignment_2]
        census_employee_2.save

        plan_year_2.update_attributes({:aasm_state => 'published'})

        @second_params = { employer_profile: employer_profile_2 }.merge(valid_person_params).merge(valid_employee_params)
        @second_employee_role, @second_census_employee = Factories::EnrollmentFactory.add_employee_role(**@second_params)
      end

      it "should still have a findable person" do
        people = Person.match_by_id_info(ssn: @ssn)
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

  describe ".add_employee_role" do
    context "when the employee already exists but is not linked" do
      let(:census_dependent){FactoryGirl.build(:census_dependent)}
      let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
        census_dependents: [census_dependent],
        )}
      let(:existing_person) {FactoryGirl.create(:person, valid_person_params)}
      let(:employee) {FactoryGirl.create(:employee_role, valid_employee_params.merge(person: existing_person, employer_profile: employer_profile))}
      before {user;census_employee;employee}

      context "with all required data" do
        let(:params) {valid_params}
        let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}
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
      # let(:benefit_group_assignment){FactoryGirl.build(:benefit_group_assignment)}
      let(:census_dependent){FactoryGirl.build(:census_dependent)}
      let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
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
        let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}

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
        let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
        let(:benefit_group_assignment) {FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, benefit_group: benefit_group)}
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
      end
    end
  end

  describe ".add_consumer_role" do
    let(:is_incarcerated) {true}
    let(:is_applicant) {true}
    let(:is_state_resident) {true}
    let(:citizen_status) {"us_citizen"}
    let(:valid_person) {FactoryGirl.create(:person)}

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
    let(:valid_person) {FactoryGirl.create(:person)}

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
    let(:user) { FactoryGirl.create(:user) }

    let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
    let(:person) { consumer_role.person }
    let(:ua_params) do
      {
        addresses: [],
        phones: [],
        emails: [],
        person: {
          "first_name" => primary.person.name_first,
          "last_name" => primary.person.name_last,
          "middle_name" => primary.person.name_middle,
          "name_pfx" => primary.person.name_pfx,
          "name_sfx" => primary.person.name_sfx,
          "dob" => primary.person_demographics.birth_date,
          "ssn" => primary.person_demographics.ssn,
          "no_ssn" => "",
          "gender" => primary.person_demographics.sex.split('#').last
        }
      }
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }
    let(:family) { consumer_role.person.primary_family }
    before :each do
      family.update_attributes!(:e_case_id => parser.integrated_case_id)
    end

    it "should not crash on updating the e_case_id" do
      expect {person.primary_family.update_attributes!(:e_case_id => "some e case id whatever")}.not_to raise_error
    end
  end

  context "with errors initializing the person" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml")) }
    let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_single_dup_payload_sample.xml"))).first }
    let(:user) { FactoryGirl.create(:user) }

    let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
    let(:person) { consumer_role.person }
    let(:ua_params) do
      {
        addresses: [],
        phones: [],
        emails: [],
        person: {
          "first_name" => primary.person.name_first,
          "last_name" => primary.person.name_last,
          "middle_name" => primary.person.name_middle,
          "name_pfx" => primary.person.name_pfx,
          "name_sfx" => primary.person.name_sfx,
          "dob" => primary.person_demographics.birth_date,
          "ssn" => primary.person_demographics.ssn,
          "no_ssn" => "",
          "gender" => primary.person_demographics.sex.split('#').last
        }
      }
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }
    let(:family) { consumer_role.person.primary_family }
    before :each do
      allow(Factories::EnrollmentFactory).to receive(:initialize_person).and_return([nil, nil])
    end

    it "should return nil for the consumer role" do
      expect(Factories::EnrollmentFactory.construct_consumer_role(ua_params,user)).not_to be
    end
  end
end

describe Factories::EnrollmentFactory, "with an exisiting consumer role" do

  context ".build_family" do
    let(:subject) { Factories::EnrollmentFactory }
    let(:person) { FactoryGirl.create(:person)}

    it "should add a family to a person without one" do
      subject.build_family(person,[])
      expect(person.primary_family).to be_truthy
    end

  end

  context ".build_family with existing family" do
    let(:subject) { Factories::EnrollmentFactory }
    let(:person) { original_family.person}
    let(:original_family) { FactoryGirl.create(:family, :with_primary_family_member) }

    it "should return primary family" do
      original_family = subject.build_family(person,[])
      expect(original_family).to eq(person.primary_family)
    end

  end


end
