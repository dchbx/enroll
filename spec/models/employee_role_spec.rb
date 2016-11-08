require 'rails_helper'

describe EmployeeRole do
  before :each do
    subject.valid?
  end

  [:hired_on, :dob, :gender, :ssn, :employer_profile_id].each do |property|
    it "should require #{property}" do
      expect(subject).to have_errors_on(property)
    end
  end

end

describe EmployeeRole, "given a person" do
  let(:hbx_id) { "555553443" }
  let(:ssn) { "012345678" }
  let(:dob) { Date.new(2009, 2, 5) }
  let(:gender) { "female" }

  let(:person) { Person.new(
    :hbx_id => hbx_id,
    :ssn => ssn,
    :dob => dob,
    :gender => gender
  )}
  subject { EmployeeRole.new(:person => person) }

  it "should have access to dob" do
    expect(subject.dob).to eq dob
  end

  it "should have access to gender" do
    expect(subject.gender).to eq gender
  end

  it "should have access to ssn" do
    expect(subject.ssn).to eq ssn
  end
  it "should have access to hbx_id" do
    expect(subject.hbx_id).to eq hbx_id
  end

end

describe "coverage_effective_on" do
  let(:employee_role) { FactoryGirl.create(:employee_role) }
  let(:effective_on) { Date.new(2009, 2, 5) }

  context "when benefit group present" do
    it "should return coverage_effective_on" do
      allow(employee_role).to receive_message_chain(:census_employee, :hired_on).and_return(employee_role.hired_on)
      allow(employee_role).to receive_message_chain(:benefit_group, :effective_on_for).and_return(effective_on)
      expect(employee_role.coverage_effective_on).to eq effective_on
    end
  end

  context "when benefit group doesn't exists" do
    it "coverage_effective_on should be nil" do
      allow(employee_role).to receive_message_chain(:census_employee, :hired_on).and_return(effective_on)
      allow(employee_role).to receive_message_chain(:benefit_group, :effective_on_for).and_return(nil)
      expect(employee_role.coverage_effective_on).to eq nil
    end
  end
end

describe EmployeeRole, dbclean: :after_each do
  let(:ssn) {"987654321"}
  let(:dob) { 36.years.ago.to_date }
  let(:gender) {"female"}
  let(:hired_on) { 10.days.ago.to_date }

  describe "built" do
    let(:address) {FactoryGirl.build(:address)}
    let(:saved_person) {FactoryGirl.create(:person, first_name: "Annie", last_name: "Lennox", addresses: [address])}
    let(:new_person) {FactoryGirl.build(:person, first_name: "Carly", last_name: "Simon")}
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}

    let(:valid_person_attributes) do
      {
        ssn: ssn,
        dob: dob,
        gender: gender,
      }
    end

    let(:valid_params) do
      {
        person_attributes: valid_person_attributes,
        employer_profile: employer_profile,
        hired_on: hired_on,
      }
    end

    context "with valid parameters" do
      let(:employee_role) {saved_person.employee_roles.build(valid_params)}

      # %w[employer_profile ssn dob gender hired_on].each do |m|
      %w[ssn dob gender hired_on].each do |m|
        it "should have the right #{m}" do
          expect(employee_role.send(m)).to eq send(m)
        end
      end

      it "should save" do
        expect(employee_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          employee_role.save
        end

        it "should be findable" do
          expect(EmployeeRole.find(employee_role.id).id.to_s).to eq employee_role.id.to_s
        end
      end
    end

    context "with no employer_profile" do
      let(:params) {valid_params.except(:employer_profile)}
      let(:employee_role) {saved_person.employee_roles.build(params)}
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on employer_profile_id" do
        expect(employee_role.errors[:employer_profile_id].any?).to be true
      end
    end
  end

  # FIXME: Replace with pattern
  it 'properly intantiates the class using an existing person' # do
=begin
    ssn = "987654321"
    date_of_hire = Date.today - 10.days
    dob = Date.today - 36.years
    gender = "female"

    employer_profile = EmployerProfile.create(
        legal_name: "ACME Widgets, Inc.",
        fein: "098765432",
        entity_kind: :c_corporation
      )

    person = Person.create(
        first_name: "annie",
        last_name: "lennox",
        addresses: [Address.new(
            kind: "home",
            address_1: "441 4th St, NW",
            city: "Washington",
            state: "DC",
            zip: "20001"
          )
        ]
      )

    employee_role = person.build_employee
    employee_role.ssn = ssn
    employee_role.dob = dob
    employee_role.gender = gender
    employee_role.employers << employer_profile._id
    employee_role.date_of_hire = date_of_hire
    expect(employee_role.touch).to eq true

    # Verify local getter methods
    expect(employee_role.employers.first).to eq employer_profile._id
    expect(employee_role.date_of_hire).to eq date_of_hire

    # Verify delegate local attribute values
    expect(employee_role.ssn).to eq ssn
    expect(employee_role.dob).to eq dob
    expect(employee_role.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender

    expect(employee_role.errors.messages.size).to eq 0
    expect(employee_role.save).to eq true
  end
=end

  # FIXME: Replace with pattern
  it 'properly intantiates the class using a new person'# do
=begin
    ssn = "987654320"
    date_of_hire = Date.today - 10.days
    dob = Date.today - 26.years
    gender = "female"

    employer_profile = employer_profile.create(
        legal_name: "Ace Ventures, Ltd.",
        fein: "098765437",
        entity_kind: "s_corporation"
      )

    person = Person.new(first_name: "carly", last_name: "simon")

    employee_role = person.build_employee
    employee_role.ssn = ssn
    employee_role.dob = dob
    employee_role.gender = gender
    # employee_role.employer_profile << employer_profile
    employee_role.date_of_hire = date_of_hire

    # Verify local getter methods
    # expect(employee_role.employers.first).to eq employer_.id
    expect(employee_role.date_of_hire).to eq date_of_hire

    # Verify delegate local attribute values
    expect(employee_role.ssn).to eq ssn
    expect(employee_role.dob).to eq dob
    expect(employee_role.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender

    expect(person.errors.messages.size).to eq 0
    expect(person.save).to eq true

    expect(employee_role.touch).to eq true
    expect(employee_role.errors.messages.size).to eq 0
    expect(employee_role.save).to eq true
  end
=end
end

describe EmployeeRole, dbclean: :after_each do
  let(:person_created_at) { 10.minutes.ago }
  let(:person_updated_at) { 8.minutes.ago }
  let(:employee_role_created_at) { 9.minutes.ago }
  let(:employee_role_updated_at) { 7.minutes.ago }
  let(:ssn) { "019283746" }
  let(:dob) { 45.years.ago.to_date }
  let(:hired_on) { 2.years.ago.to_date }
  let(:gender) { "male" }

  context "when created" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

    let(:person) {
      FactoryGirl.create(:person,
        created_at: person_created_at,
        updated_at: person_updated_at
      )
    }

    let(:employee_role) {
      person.employee_roles.create(
        employer_profile: employer_profile,
        hired_on: hired_on,
        created_at: employee_role_created_at,
        updated_at: employee_role_updated_at,
        person_attributes: {
          ssn: ssn,
          dob: dob,
          gender: gender,
        }
      )
    }

    it "parent created_at should be right" do
      expect(person.created_at).to eq person_created_at
    end

    it "parent updated_at should be right" do
      expect(person.updated_at).to eq person_updated_at
    end

    it "created_at should be right" do
      expect(employee_role.created_at).to eq employee_role_created_at
    end

    it "updated_at should be right" do
      expect(employee_role.updated_at).to eq employee_role_updated_at
    end

    context "then parent updated" do
      let(:middle_name) { "Albert" }
      before do
        person.middle_name = middle_name
        person.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then parent touched" do
      before do
        person.touch
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should not have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then a nested parent attribute is updated" do
      before do
        employee_role.ssn = "647382910"
        employee_role.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then updated" do
      let(:new_hired_on) { 10.days.ago.to_date }

      before do
        employee_role.hired_on = new_hired_on
        employee_role.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should have changed" do
        expect(employee_role.updated_at).to be > employee_role_updated_at
      end
    end

    context "then touched" do
      before do
        employee_role.touch
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should have changed" do
        expect(employee_role.updated_at).to be > employee_role_updated_at
      end
    end
  end

  context "with saved employee roles from multiple employers" do
    let(:match_size)                  { 5 }
    let(:non_match_size)              { 3 }
    let(:match_employer_profile)      { FactoryGirl.create(:employer_profile) }
    let(:non_match_employer_profile)  { FactoryGirl.create(:employer_profile) }
    let!(:match_employee_roles)       { FactoryGirl.create_list(:employee_role, 5, employer_profile: match_employer_profile) }
    let!(:non_match_employee_roles)   { FactoryGirl.create_list(:employee_role, 3, employer_profile: non_match_employer_profile) }
    let(:first_match_employee_role)   { match_employee_roles.first }
    let(:first_non_match_employee_role)   { non_match_employee_roles.first }
    let(:ee_ids)   { [first_match_employee_role.id, first_non_match_employee_role.id] }

    it "should find employee roles using a list of ids" do
      expect(EmployeeRole.ids_in(ee_ids).size).to eq ee_ids.size
      expect(EmployeeRole.ids_in([first_match_employee_role.id]).first).to eq first_match_employee_role
    end

    it "finds all employee roles" do
      expect(EmployeeRole.all.size).to eq (match_size + non_match_size)
      expect(EmployeeRole.all.first).to be_an_instance_of EmployeeRole
    end

    it "finds first employee role" do
      expect(EmployeeRole.first).to be_an_instance_of EmployeeRole
    end

    it "should find employee roles from the provided employer profile" do
      expect(EmployeeRole.find_by_employer_profile(match_employer_profile).size).to eq match_size
      expect(EmployeeRole.find_by_employer_profile(match_employer_profile).first).to be_an_instance_of EmployeeRole
    end
  end
end


describe EmployeeRole, dbclean: :after_each do

  let(:employer_profile)          { FactoryGirl.create(:employer_profile) }
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:middle_of_prev_year) { Date.new(calender_year - 1, 6, 10) }

  let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year) }
  let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }

  let(:employee_role) {
    person.employee_roles.create(
      employer_profile: employer_profile,
      hired_on: census_employee.hired_on,
      census_employee_id: census_employee.id
      )
  }

  let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:plan_year_start_on) { Date.new(calender_year, 1, 1) }
  let(:plan_year_end_on) { Date.new(calender_year, 12, 31) }
  let(:open_enrollment_start_on) { Date.new(calender_year - 1, 12, 1) }
  let(:open_enrollment_end_on) { Date.new(calender_year - 1, 12, 10) }

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  let!(:plan_year) {

    py = FactoryGirl.create(:plan_year,
      start_on: plan_year_start_on,
      end_on: plan_year_end_on,
      open_enrollment_start_on: open_enrollment_start_on,
      open_enrollment_end_on: open_enrollment_end_on,
      employer_profile: employer_profile
      )

    blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
    white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
    py.benefit_groups = [blue, white]
    py.save
    py.update_attributes(:aasm_state => 'published')
    py
  }


  let(:benefit_group_assignment) {
    BenefitGroupAssignment.create({
      census_employee: census_employee,
      benefit_group: plan_year.benefit_groups.first,
      start_on: plan_year_start_on
      })
  }

  before do
    allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
  end

  context ".is_under_open_enrollment?" do
    context 'when under open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on)
      end

      it "should return true" do
        expect(employee_role.is_under_open_enrollment?).to be_truthy
      end
    end

    context 'when outside open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_end_on + 5.days)
      end

      it "should return false" do
        expect(employee_role.is_under_open_enrollment?).to be_falsey
      end
    end
  end

  context ".is_eligible_to_enroll_without_qle?" do
    context 'when new hire open enrollment period available' do
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: (plan_year_start_on + 10.days), updated_at: (plan_year_start_on + 10.days), hired_on: (plan_year_start_on + 10.days)) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 15.days)
      end

      it "should return true" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_truthy
      end
    end


    context 'when new roster entry enrollment period available' do
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: (plan_year_start_on + 10.days), updated_at: (plan_year_start_on + 10.days), hired_on: middle_of_prev_year) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 15.days)
      end

      it "should return true" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_truthy
      end
    end

    context 'when outside new hire enrollment period and employer open enrolment' do
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: (plan_year_start_on + 10.days), updated_at: (plan_year_start_on + 10.days), hired_on: (plan_year_start_on + 10.days)) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 55.days)
      end

      it "should return false" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_falsey
      end
    end
  end

  context "can_select_coverage?" do
    let(:employee_role) { FactoryGirl.build(:employee_role) }

    it "should return true when hired_on is less than two monthes ago" do
      employee_role.hired_on = TimeKeeper.date_of_record - 15.days
      expect(employee_role.can_select_coverage?).to eq true
    end

    it "should return false when hired_on is more than two monthes ago" do
      employee_role.hired_on = TimeKeeper.date_of_record - 75.days
      expect(employee_role.can_select_coverage?).to eq false
    end
  end
end

describe EmployeeRole do

  context 'is_dental_offered?' do

    let!(:employer_profile) {
      org = FactoryGirl.create :organization, legal_name: "Corp 1"
      FactoryGirl.create :employer_profile, organization: org
    }

    let!(:renewal_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year + 1, hios_id: "11111111122302-01", csr_variant_id: "01")
    }

    let!(:plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
    }

    let!(:current_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :active
    }

    let!(:current_benefit_group){
      FactoryGirl.create :benefit_group, plan_year: current_plan_year, reference_plan_id: plan.id
    }

    let!(:family) {
      FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
      ce = FactoryGirl.create :census_employee, employer_profile: employer_profile
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      employee_role.census_employee.add_benefit_group_assignment current_benefit_group, current_benefit_group.start_on
      employee_role.census_employee.save!
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    }

    let(:ce) { employer_profile.census_employees.non_business_owner.first }

    let(:employee_role) { family.primary_applicant.person.employee_roles.first }

    context "EE for New ER who's offering Dental trying to purchase coverage during open enrollment" do

      let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:end_on) { start_on + 1.year - 1.day }
      let(:open_enrollment_start_on) { start_on - 1.month }
      let(:open_enrollment_end_on) { open_enrollment_start_on + 9.days }

      before do
        allow(current_benefit_group).to receive(:is_offering_dental?).and_return(true)
      end

      context 'When benefit package assigned' do
        it 'should retrun true' do
          expect(employee_role.is_dental_offered?).to be_truthy
        end
      end
    end

    context "EE for Renewing ER who's offering Dental trying to purchase coverage during open enrollment" do

      let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year }
      let(:end_on) { start_on + 1.year - 1.day }
      let(:open_enrollment_start_on) { start_on - 1.month }
      let(:open_enrollment_end_on) { open_enrollment_start_on + 9.days }

      let!(:renewing_plan_year) {
        FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, end_on: end_on + 1.year, open_enrollment_start_on: open_enrollment_start_on + 1.year, open_enrollment_end_on: open_enrollment_end_on + 1.year + 3.days, fte_count: 2, aasm_state: :renewing_published
      }

      let!(:renewal_benefit_group){ FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: renewal_plan.id }
      let!(:renewal_benefit_group_assignment) { ce.add_renew_benefit_group_assignment renewal_benefit_group }

      before do
        allow(current_benefit_group).to receive(:is_offering_dental?).and_return(false)
        allow(renewal_benefit_group).to receive(:is_offering_dental?).and_return(true)
      end

      context 'When benefit package assigned' do

        it 'should retrun true' do
          employee_role.census_employee.add_renew_benefit_group_assignment renewal_benefit_group
          employee_role.census_employee.save!
          expect(employee_role.is_dental_offered?).to be_truthy
        end
      end
    end
  end
end
