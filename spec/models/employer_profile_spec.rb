require 'rails_helper'

describe EmployerProfile, dbclean: :after_each do

  let(:entity_kind)     { "partnership" }
  let(:bad_entity_kind) { "fraternity" }
  let(:entity_kind_error_message) { "#{bad_entity_kind} is not a valid business entity kind" }

  let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
  let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
  let(:email  )  { Email.new(kind: "work", address: "info@sailaway.org") }

  let(:office_location) { OfficeLocation.new(
        is_primary: true,
        address: address,
        phone: phone
      )
    }

  let(:organization) { Organization.create(
      legal_name: "Sail Adventures, Inc",
      dba: "Sail Away",
      fein: "001223333",
      office_locations: [office_location]
      )
    }

  let(:valid_params) do
    {
      organization: organization,
      entity_kind: entity_kind
    }
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  it { should validate_presence_of :entity_kind }

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }
      let(:employer_profile) {EmployerProfile.new(**params)}

      it "should initialize nested models" do
        expect(employer_profile.inbox).not_to be_nil
      end

      it "should not save" do
        expect(employer_profile.save).to be_falsey
      end
    end

    context "with no entity_kind" do
      def params; valid_params.except(:entity_kind); end

      it "should fail validation " do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_truthy
      end
    end

    context "with improper entity_kind" do
      def params; valid_params.deep_merge({entity_kind: bad_entity_kind}); end
      it "should fail validation with improper entity_kind" do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_truthy
        expect(EmployerProfile.create(**params).errors[:entity_kind]).to eq [entity_kind_error_message]
      end
    end

    context "with all valid arguments" do
      def params; valid_params; end
      def employer_profile; EmployerProfile.new(**params); end

      it "should initialize employer profile workflow state to applicant" do
        expect(employer_profile.applicant?).to be_truthy
      end

      it "should save" do
        expect(employer_profile.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_employer_profile) do
          er = employer_profile
          er.save
          er
        end

        it "should save all nested models" do
          expect(saved_employer_profile.inbox?).to be_truthy
        end

        it "and should be findable" do
          expect(EmployerProfile.find(saved_employer_profile.id).id.to_s).to eq saved_employer_profile.id.to_s
        end

        it "should return nil with invalid id" do
          expect(EmployerProfile.find("invalid_id")).to eq nil
        end
      end
    end
  end

  context "can_transmit_xml?" do
    context "for new employer" do
      let(:new_plan_year){ FactoryGirl.build(:plan_year) }
      let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [new_plan_year]) }

      it "should return true if its new employer and does not have binder paid status" do
        expect(employer_profile.can_transmit_xml?).to be_truthy
      end

      it "should return false if employer has binder paid status" do
        employer_profile.aasm_state = "binder_paid"
        employer_profile.save
        expect(employer_profile.can_transmit_xml?).to be_falsey
      end
    end

    context "for renewing employer" do
      let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
      let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year]) }

      it "should return false if its renewing employer" do
        expect(employer_profile.can_transmit_xml?).to be_falsey
      end
    end
  end

  context "has registered and enters initial application process" do
    let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group]) }
    let!(:employer_profile)  { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }
    let(:min_non_owner_count )  { Settings.aca.shop_market.non_owner_participation_count_minimum }

    it "should initialize in applicant status" do
      expect(employer_profile.applicant?).to be_truthy
    end

    context "and employer submits a valid plan year application with tomorrow as start open enrollment" do
      before do
        plan_year = employer_profile.plan_years.first
        plan_year.start_on = TimeKeeper.date_of_record.beginning_of_month.next_month
        plan_year.open_enrollment_start_on = TimeKeeper.date_of_record.beginning_of_month
        plan_year.open_enrollment_end_on = plan_year.open_enrollment_start_on + 9.days
        plan_year.end_on = plan_year.start_on + 1.year - 1.day

        TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record.beginning_of_month - 1)
        plan_year.publish!
      end

      it "should transition to registered state" do
        expect(employer_profile.registered?).to be_truthy
      end
    end

    context "and today is the day following this month's deadline for start of open enrollment" do
      before do
        # employer_profile.advance_enrollment_period
      end

      context "and employer profile is in applicant state" do
        context "and effective date is next month" do
          it "should change status to canceled"
        end

        context "and effective date is later than next month" do
          it "should not change state"
        end
      end

      context "and employer is in ineligible or ineligible_appealing state" do
        it "what should be done?"
      end
    end
  end

  context ".show_plan_year" do
    let(:active_plan_year)     { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'active') }
    let(:employer_profile)     { EmployerProfile.new(**valid_params, plan_years: [active_plan_year, renewing_plan_year]) }

    let(:renewing_plan_year)   {
      FactoryGirl.build(:plan_year,
        open_enrollment_start_on: TimeKeeper.date_of_record - 1.day,
        open_enrollment_end_on: TimeKeeper.date_of_record + 10.days,
        start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day,
        end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year,
        aasm_state: 'renewing_enrolling')
    }

    context 'when renewing published plan year present' do

      it 'should return renewing published plan year' do
        expect(employer_profile.show_plan_year).to eq renewing_plan_year
      end
    end

    context 'when renewing published plan year not present' do

      before do
        employer_profile.plan_years = [active_plan_year]
      end

      it 'should retrun active plan year' do
        expect(employer_profile.show_plan_year).to eq active_plan_year
      end
    end

    context 'when renewing and active plan year not present' do

      let(:published_plan_year)  { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day, end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year, aasm_state: 'published') }
      let(:employer_profile)     { EmployerProfile.new(**valid_params, plan_years: [published_plan_year]) }

      it 'should return published plan year' do
        expect(employer_profile.show_plan_year).to eq published_plan_year
      end
    end

    context 'when employer did not publish plan year' do

      let(:draft_plan_year)  { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day, end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year, aasm_state: 'draft') }
      let(:employer_profile)     { EmployerProfile.new(**valid_params, plan_years: [draft_plan_year]) }

      it 'should return nil' do
        expect(employer_profile.show_plan_year).to be_nil
      end
    end

    context 'when draft plan year present' do

      let(:draft_plan_year)  { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day, end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year, aasm_state: 'draft') }
      let(:employer_profile)     { EmployerProfile.new(**valid_params, plan_years: [draft_plan_year]) }

      it 'should return draft plan year' do
        expect(employer_profile.draft_plan_year).to eq [draft_plan_year]
      end
    end
  end

   context "binder paid methods" do
     let(:renewing_plan_year)    { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'renewing_enrolling') }
     let(:new_plan_year)    { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month , end_on: TimeKeeper.date_of_record.end_of_month + 1.year, aasm_state: 'enrolling') }
     let(:new_employer)     { EmployerProfile.new(**valid_params, plan_years: [new_plan_year]) }
     let(:renewing_employer)     { EmployerProfile.new(**valid_params, plan_years: [renewing_plan_year]) }

     before do
       renewing_employer.save!
       new_employer.save!
     end

     it "#instance methods" do
       expect(new_employer.is_new_employer?).to eq true
       expect(renewing_employer.is_renewing_employer?).to eq true
       expect(renewing_employer.plan_years.renewing).to eq renewing_plan_year.to_a
       expect(new_employer.has_next_month_plan_year?).to eq true
     end

   end

  context ".billing_plan_year" do
    let(:active_plan_year)    { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'published') }
    let(:employer_profile)    { EmployerProfile.new(**valid_params, plan_years: [active_plan_year, renewing_plan_year]) }
    let(:renewing_plan_year)   {
      FactoryGirl.build(:plan_year,
        open_enrollment_start_on: TimeKeeper.date_of_record + 1.day,
        open_enrollment_end_on: TimeKeeper.date_of_record + 10.days,
        start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day,
        end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year,
        aasm_state: 'renewing_published')
    }

    before do
      #patchy 1st of month spec fix
      if employer_profile.plan_years.last.valid?
        employer_profile.save!
      else
        employer_profile.plan_years.last.open_enrollment_start_on += 1.day
        employer_profile.save!
      end
    end

    context 'when upcoming month plan year present' do

      let(:renewing_plan_year)   { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, end_on: TimeKeeper.date_of_record.end_of_month + 1.year, aasm_state: 'renewing_published') }

      it 'should return upcoming month plan year' do
        plan_year, billing_date = employer_profile.billing_plan_year

        expect(plan_year).to eq renewing_plan_year
        expect(billing_date).to eq TimeKeeper.date_of_record.next_month
      end
    end

    context 'when future plan year is under open enrollment present' do
      let(:renewing_plan_year)   {
        FactoryGirl.build(:plan_year,
          open_enrollment_start_on: TimeKeeper.date_of_record - 1.day,
          open_enrollment_end_on: TimeKeeper.date_of_record + 10.days,
          start_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.day,
          end_on: TimeKeeper.date_of_record.next_month.end_of_month + 1.year,
          aasm_state: 'renewing_published')
      }

      it 'should return future plan year' do
        plan_year, billing_date = employer_profile.billing_plan_year
        expect(plan_year).to eq renewing_plan_year
        expect(billing_date).to eq renewing_plan_year.start_on
      end
    end

    context 'when active plan year and future non open enrollment plan year present' do

      it 'should return active plan year' do
        plan_year, billing_date = employer_profile.billing_plan_year
        expect(plan_year).to eq active_plan_year
        expect(billing_date).to eq TimeKeeper.date_of_record
      end
    end

    context 'when only future non open enrollment plan year present' do

      let(:employer_profile)     { EmployerProfile.new(**valid_params, plan_years: [renewing_plan_year]) }

      it 'should return active plan year' do
        plan_year, billing_date = employer_profile.billing_plan_year
        expect(plan_year).to eq renewing_plan_year
        expect(billing_date).to eq renewing_plan_year.start_on
      end
    end
  end

  context "has hired a broker" do
  end

  context ".benefit_group_assignments" do

    before do
      DatabaseCleaner.clean
    end

    let(:benefit_group) { FactoryGirl.build(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group]) }
    let(:employer_profile) { plan_year.employer_profile }
    let!(:census_employees) { FactoryGirl.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment])}
    let!(:benefit_group_assignment) { FactoryGirl.build_stubbed(:benefit_group_assignment, benefit_group: benefit_group) }
    let!(:people) { FactoryGirl.create_list(:person, 2) }
    let!(:person0) { FactoryGirl.create(:person, :with_employee_role, ssn: census_employees[0].ssn, last_name: census_employees[0].last_name) }
    let!(:person1) { FactoryGirl.create(:person, :with_employee_role,  ssn: census_employees[1].ssn, last_name: census_employees[1].last_name) }

    it "should return all of the benefit group assignments of the employer profile" do
      expect(employer_profile.benefit_group_assignments.size).to eq 2
    end

  end

  context "has employees that have enrolled in coverage" do
    let(:benefit_group)       { FactoryGirl.build(:benefit_group)}
    let(:plan_year)           { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group]) }
    let!(:employer_profile)   { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }
    let(:census_employees)    { FactoryGirl.create_list(:census_employee, 7,
                                  employer_profile: employer_profile,
                                  benefit_group_assignments: [benefit_group]
                                )
                              }
    let(:person0)  { FactoryGirl.create(:person, ssn: census_employees[0].ssn, last_name: census_employees[0].last_name) }
    let(:person0)  { FactoryGirl.create(:person, ssn: census_employees[1].ssn, last_name: census_employees[1].last_name) }
    let!(:ee0)    { FactoryGirl.create(:employee_role, person: people[0], employer_profile: employer_profile) }
    let!(:ee1)    { FactoryGirl.create(:employee_role, person: people[1], employer_profile: employer_profile) }
    # let(:employees)         { FactoryGirl.create_list(:employee_role, employee_count, employer_profile: employer_profile) }
    let!(:ee_roles)          { employer_profile.employee_roles }


    before do
      census_employees.each
    end

  end
end

describe EmployerProfile, "given multiple existing employer profiles", :dbclean => :after_all do
  before(:all) do
    home_office = FactoryGirl.build(:office_location, :primary)
    @er0 = EmployerProfile.new(entity_kind: "partnership")
    @er1 =  EmployerProfile.new(entity_kind: "partnership")
    @er2 = EmployerProfile.new(entity_kind: "partnership")
    @er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office])
    @er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office])
    @er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office])
    @no_employer_org = Organization.create!(fein: "123456789", office_locations: [home_office], legal_name: "I AM NOT AN EMPLOYER")
  end


  it "should be able to find those profiles with the .all class method" do
    expect(EmployerProfile.all).to include(@er0)
    expect(EmployerProfile.all).to include(@er1)
    expect(EmployerProfile.all).to include(@er2)
  end

  it "should not return any organizations which do not have employers" do
    expect(EmployerProfile.all).not_to include(@no_employer_org)
  end
end

describe EmployerProfile, "given an unlinked, linkable census employee with a family" do
  let(:census_dob) { Date.new(1983,2,15) }
  let(:census_ssn) { "123456789" }

  let(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let(:plan_year) { benefit_group.plan_year }

  let(:employer_profile) { plan_year.employer_profile }
  let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
  let(:census_employee) { CensusEmployee.new(
    :ssn => census_ssn,
    :dob => census_dob,
    :gender => "male",
    :employer_profile_id => employer_profile.id,
    :first_name => "Roger",
    :last_name => "Martin",
    :hired_on => 20.days.ago,
    :is_business_owner => false,
    :benefit_group_assignments => [benefit_group_assignment]
  ) }


  before do
    plan_year.update_attributes({:aasm_state => 'published'})
  end

  it "should not find the linkable family when given a different ssn" do
    person = OpenStruct.new({
      :dob => census_dob,
      :ssn => "987654321"
    })
    expect(EmployerProfile.find_census_employee_by_person(person)).to eq []
  end

  it "should not find the linkable family when given a different dob" do
    person = OpenStruct.new({
      :dob => Date.new(2012,1,1),
      :ssn => census_ssn
    })
    expect(EmployerProfile.find_census_employee_by_person(person)).to eq []
  end

  it "should return the linkable employee when given the same dob and ssn" do
    person = OpenStruct.new({
      :dob => census_dob,
      :ssn => census_ssn
    })
    census_employee.save
    expect(EmployerProfile.find_census_employee_by_person(person)).to eq [census_employee]
  end
end

describe EmployerProfile, "Class methods", dbclean: :after_each do
  def er0; EmployerProfile.new(entity_kind: "partnership"); end
  def er1; EmployerProfile.new(entity_kind: "partnership"); end
  def er2; EmployerProfile.new(entity_kind: "partnership"); end

  def ee0; FactoryGirl.build(:census_employee, ssn: "369851245", dob: 32.years.ago.to_date, employer_profile_id: er0.id); end
  def ee1; FactoryGirl.build(:census_employee, ssn: "258741239", dob: 42.years.ago.to_date, employer_profile_id: er1.id); end


  def home_office; FactoryGirl.build(:office_location); end

  def organization0; er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office]); end
  def organization1; er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office]); end
  def organization2; er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office]); end
  before { organization0; organization1; organization2 }

  describe '.find_by_broker_agency_profile' do
    let(:organization6)  {FactoryGirl.create(:organization, fein: "024897585")}
    let(:broker_agency_profile)  {organization6.create_broker_agency_profile(market_kind: "both", primary_broker_role_id: "8754985")}
    let(:organization7)  {FactoryGirl.create(:organization, fein: "724897585")}
    let(:broker_agency_profile7)  {organization7.create_broker_agency_profile(market_kind: "both", primary_broker_role_id: "7754985")}
    let(:organization3)  {FactoryGirl.create(:organization, fein: "034267123")}
    let(:organization4)  {FactoryGirl.create(:organization, fein: "027636010")}
    let(:organization5)  {FactoryGirl.create(:organization, fein: "076747654")}

    def er3; organization3.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile); end
    def er4; organization4.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile); end
    def er5; organization5.create_employer_profile(entity_kind: "partnership"); end
    before { broker_agency_profile; er3; er4; er5 }

    it 'returns employers represented by the specified broker agency' do
      expect(er3.broker_agency_profile.id).to eq broker_agency_profile.id
      expect(er4.broker_agency_profile.id).to eq broker_agency_profile.id
      expect(er5.broker_agency_profile).to be_nil
      employers_with_broker = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile)
      expect(employers_with_broker.first).to be_a EmployerProfile
    end

    it 'shows two employers with broker' do
      employers_with_broker = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile)
      employers_with_broker7 = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile7)
      expect(employers_with_broker.size).to eq 2
      expect(employers_with_broker7.size).to eq 0
    end

    it 'shows one employer moving to another broker agency' do
      employer =  organization5.create_employer_profile(entity_kind: "partnership");
      employer.hire_broker_agency(broker_agency_profile7)
      employer.save
      employers_with_broker7 = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile7)
      expect(employers_with_broker7.size).to eq 1
      employer = Organization.find(employer.organization.id).employer_profile
      employer.hire_broker_agency(broker_agency_profile)
      employer.save
      employers_with_broker7 = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile7)
      expect(employers_with_broker7.size).to eq 0
    end

    it 'shows an employer selected a broker for the first time' do
      employer = er5
      employer.hire_broker_agency(broker_agency_profile7)
      employer.save
      employers_with_broker = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile)
      employers_with_broker7 = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile7)
      expect(employers_with_broker.size).to eq 2
      expect(employers_with_broker7.size).to eq 1
    end

    it 'works with multiple broker_agency_contacts'  do
      employer = er5
      org_id = employer.organization.id
      employer.hire_broker_agency(broker_agency_profile7)
      employer.save
      employer.hire_broker_agency(broker_agency_profile)
      employer.save
      employer.hire_broker_agency(broker_agency_profile7)
      employer.save
      employers_with_broker7 = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile7)
      expect(employers_with_broker7.size).to eq(1)
    end
  end

  describe ".find_by_fein" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile) }
    it "should return record for matching fein" do
      employer_profile.save
      expect(EmployerProfile.find_by_fein(employer_profile.organization.fein)).to be_an_instance_of EmployerProfile
    end
  end

  describe ".staff_roles" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile) }

    context "has no staff" do
      it "should return any staff" do
        expect(employer_profile.staff_roles).to eq []
      end
    end

    context "has staff" do
      let(:owner_person) { instance_double("Person")}

      it "should return an array of persons" do
        allow(Person).to receive(:staff_for_employer).with(employer_profile).and_return([owner_person])
        expect(employer_profile.staff_roles).to include(owner_person)
      end
    end
  end

  describe "match_employer" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile) }
    let(:person) { FactoryGirl.build(:person) }
    let(:user) { FactoryGirl.build(:user) }

    it "should get employer form staff_roles" do
      allow(user).to receive(:person).and_return person
      allow(employer_profile).to receive(:staff_roles).and_return [person]
      expect(employer_profile.match_employer(user)).to eq person
    end
  end

  describe ".find_census_employee_by_person" do
    context "with person not matching ssn" do
      let(:params) do
        {  ssn:        "019283746",
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        ee0.dob
        }
      end
      def p0; Person.new(**params); end

      it "should return an empty array" do
        expect(EmployerProfile.find_census_employee_by_person(p0)).to eq []
      end
    end

    context "with person not matching dob" do
      let(:params) do
        {  ssn:        ee0.ssn,
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        (ee0.dob - 1.year).to_date
        }
      end
      def p0; Person.new(**params); end

      it "should return an empty array" do
        expect(EmployerProfile.find_census_employee_by_person(p0)).to eq []
      end
    end

    context "with person matching ssn and dob" do
      let(:benefit_group) { FactoryGirl.create(:benefit_group) }
      let(:plan_year) { benefit_group.plan_year }
      let(:employer_profile) { plan_year.employer_profile }
      let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group) }
      let(:census_employee) { FactoryGirl.create(:census_employee, ssn: ee0.ssn, dob: ee0.dob, employer_profile_id: employer_profile.id, benefit_group_assignments: [benefit_group_assignment]) }
      let(:params) do
        {  ssn:        ee0.ssn,
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        ee0.dob
        }
      end
      def p0; Person.new(**params); end
      before do
        plan_year.update_attributes({:aasm_state => 'published'})
      end

      it "should return an instance of CensusEmployee" do
        # expect(organization0.save).errors.messages).to eq ""
        census_employee.valid?
        expect(EmployerProfile.find_census_employee_by_person(p0).first).to be_a CensusEmployee
      end

      it "should return employee_families where employee matches person" do
        census_employee.valid?
        expect(EmployerProfile.find_census_employee_by_person(p0).size).to eq 1
      end

      it "returns employee_families where employee matches person" do
        census_employee.valid?
        expect(EmployerProfile.find_census_employee_by_person(p0).first.dob).to eq census_employee.dob
      end
    end
  end

  describe ".find_all_by_person" do
    let(:black_and_decker) do
      org = FactoryGirl.create(:organization, legal_name: "Black and Decker, Inc.", dba: "Black Decker")
      er = org.create_employer_profile(entity_kind: "c_corporation")
    end
    let(:atari) do
      org = FactoryGirl.create(:organization, legal_name: "Atari Corporation", dba: "Atari Games")
      er = org.create_employer_profile(entity_kind: "s_corporation")
    end
    let(:google) do
      org = FactoryGirl.create(:organization, legal_name: "Google Inc.", dba: "Google")
      er = org.create_employer_profile(entity_kind: "partnership")
    end
    def bob_params; {first_name: "Uncle", last_name: "Bob", ssn: "999441111", dob: 35.years.ago.to_date}; end
    let!(:black_and_decker_bob) do
      ee = FactoryGirl.create(:census_employee, employer_profile_id: black_and_decker.id,  **bob_params)
    end
    let!(:atari_bob) do
      ee = FactoryGirl.create(:census_employee, employer_profile_id: atari.id, **bob_params)
    end
    let!(:google_bob) do
      # different dob
      ee = FactoryGirl.create(:census_employee, employer_profile_id: google.id, **bob_params.merge(dob: 40.years.ago.to_date))
    end

    def valid_ssn; ee0.ssn; end
    def invalid_ssn; "000000000"; end
    let(:params) do
      {
        first_name: ee0.first_name,
        last_name:  ee0.last_name,
        dob:        ee0.dob
      }
    end

    before do
      [black_and_decker, atari, google].each() do |employer_profile|
        plan_year = FactoryGirl.build(:plan_year, employer_profile: employer_profile)
        benefit_group = FactoryGirl.build(:benefit_group, plan_year: plan_year)
        plan_year.save
        benefit_group.save

        employer_profile.census_employees.each() do |census_employee|
          benefit_group_assignment = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)
          census_employee.benefit_group_assignments = [benefit_group_assignment]
          census_employee.save
        end
        plan_year.update_attributes({:aasm_state => 'published'})
      end
    end

    context "finds an EmployerProfile employee" do
      def valid_person; FactoryGirl.build(:person, **bob_params); end

      it "should find the active employee in multiple employer_profiles" do
        # it shouldn't find google bob because dob are different
        expect(EmployerProfile.find_census_employee_by_person(valid_person).size).to eq 2
      end

      it "should return EmployerProfile" do
        expect(EmployerProfile.find_census_employee_by_person(valid_person).first.employer_profile).to be_a EmployerProfile
      end

      it "should include the matching employee" do
        found = EmployerProfile.find_census_employee_by_person(valid_person).last
        [:first_name, :last_name, :ssn, :dob].each do |attr|
          expect(found.send(attr)).to eq valid_person.send(attr)
        end
      end
    end

    context "fails to match an employee" do
      def invalid_person; Person.new(**params.merge(ssn: invalid_ssn)); end

      it "should not return any matches" do
        # expect(invalid_person.ssn).to eq invalid_ssn
        expect(EmployerProfile.find_census_employee_by_person(invalid_person).size).to eq 0
      end
    end
  end
end

describe EmployerProfile, "instance methods" do
  let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
  let(:census_employee)  { FactoryGirl.build(:census_employee, ssn: "069851240", dob: 34.years.ago.to_date, employer_profile_id: employer_profile.id)}
  let(:person)           { Person.new(first_name: census_employee.first_name, last_name: census_employee.last_name, ssn: census_employee.ssn, dob: 34.years.ago.to_date)}

  describe "#employee_roles" do
    let(:people)  { FactoryGirl.create_list(:person, 2) }
    let!(:ee0)  { FactoryGirl.create(:employee_role, person: people[0], employer_profile: employer_profile) }
    let!(:ee1)  { FactoryGirl.create(:employee_role, person: people[1], employer_profile: employer_profile) }
    # let(:employees)         { FactoryGirl.create_list(:employee_role, employee_count, employer_profile: employer_profile) }
    let!(:ee_roles)          { employer_profile.employee_roles }

    context "an employer profile with multiple associated employee roles" do
      it "should find all employees" do
        expect(ee_roles.size).to eq 2
      end

      it "should return array of employee_role instances" do
        expect(ee_roles.first).to be_a EmployeeRole
      end

      it "should be associated with correct employer profile" do
        expect(ee_roles.first.employer_profile).to eq employer_profile
      end
    end
  end
end

describe EmployerProfile, "roster size" do
  let(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let(:census_employee1) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, aasm_state: 'eligible')}
  let(:census_employee2) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id).update(aasm_state: 'employee_role_linked')}
  let(:census_employee3) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id).update(aasm_state: 'employment_terminated')}
  let(:census_employee4) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id).update(aasm_state: 'rehired')}

  it "should got 2" do
    census_employee1
    census_employee2
    census_employee3
    census_employee4
    expect(employer_profile.roster_size).to eq 2
  end
end

describe EmployerProfile, "when a binder premium is credited" do
  let(:hbx_id) { "some hbx id string value" }
  let(:employer) { EmployerProfile.new(:aasm_state => :eligible, :organization => Organization.new(:hbx_id => hbx_id)) }

  it "should send the notification broadcast" do
    @employer_id = nil
    event_subscriber = ActiveSupport::Notifications.subscribe(EmployerProfile::BINDER_PREMIUM_PAID_EVENT_NAME) do |e_name, s_at, e_at, m_id, payload|
      @employer_id = payload.stringify_keys["employer_id"]
    end
    employer.binder_credited
    ActiveSupport::Notifications.unsubscribe(event_subscriber)
    expect(@employer_id).to eq hbx_id
  end
end

describe EmployerProfile, "Renewal Queries" do
  let(:organization1) {
    org = FactoryGirl.create :organization, legal_name: "Corp 1"
    employer = FactoryGirl.create :employer_profile, organization: org
    2.times{ FactoryGirl.create :plan_year, employer_profile: employer, aasm_state: :draft }
    org
  }

  let(:organization2) {
    org = FactoryGirl.create :organization, legal_name: "Corp 2"
    employer = FactoryGirl.create :employer_profile, organization: org
    FactoryGirl.create :plan_year, employer_profile: employer, aasm_state: :draft
    org
  }

  let(:organization3) {
    org = FactoryGirl.create :organization, legal_name: "Corp 3"
    employer = FactoryGirl.create :employer_profile, organization: org
    2.times{ FactoryGirl.create :plan_year, employer_profile: employer, aasm_state: :draft }
    org
  }

  let(:organization4) {
    org = FactoryGirl.create :organization, legal_name: "Corp 4"
    employer = FactoryGirl.create :employer_profile, organization: org
    plan_year = FactoryGirl.create :plan_year, employer_profile: employer, aasm_state: :draft
    org
  }

  let(:calender_year) { TimeKeeper.date_of_record.year }

  before do
    plan_years = organization1.employer_profile.plan_years.to_a
    plan_years.first.update_attributes({ aasm_state: :renewing_published,
      :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 13)
      })
    plan_years.last.update_attributes({ aasm_state: :active,
      :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year-1, 4, 1), :open_enrollment_end_on => Date.new(calender_year-1, 4, 10)
      })

    organization2.employer_profile.plan_years.first.update_attributes({ aasm_state: :published,
      :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10)
      })

    plan_years = organization3.employer_profile.plan_years.to_a
    plan_years.first.update_attributes({ aasm_state: :renewing_draft,
      :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 13)
      })
    plan_years.last.update_attributes({ aasm_state: :active,
      :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year-1, 4, 1), :open_enrollment_end_on => Date.new(calender_year-1, 4, 10)
      })

    organization4.employer_profile.plan_years.first.update_attributes({ aasm_state: :draft,
      :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10)
      })
  end

  context '.organizations_for_open_enrollment_begin', dbclean: :after_each do
    it 'should return organizations elgible for open enrollment' do
      expect(EmployerProfile.organizations_for_open_enrollment_begin(Date.new(calender_year, 4, 1)).to_a).to eq [organization1, organization2]
    end
  end

  context '.organizations_for_open_enrollment_end', dbclean: :after_each do
    it 'should return organizations for whom open enrollment ended' do
      expect(EmployerProfile.organizations_for_open_enrollment_end(Date.new(calender_year, 4, 10)).to_a).to be_blank
      expect(EmployerProfile.organizations_for_open_enrollment_end(Date.new(calender_year, 4, 11)).to_a).to eq [organization2]
      expect(EmployerProfile.organizations_for_open_enrollment_end(Date.new(calender_year, 4, 14)).to_a).to eq [organization1, organization2]
    end
  end

  context '.organizations_for_plan_year_begin', dbclean: :after_each do
    it 'should return organizations eligible to begin plan year' do
      expect(EmployerProfile.organizations_for_plan_year_begin(Date.new(calender_year, 4, 30)).to_a).to be_blank
      expect(EmployerProfile.organizations_for_plan_year_begin(Date.new(calender_year, 5, 1)).to_a).to eq [organization1, organization2]
    end
  end

  context '.organizations_for_plan_year_end', dbclean: :after_each do
    it 'should return organizations for whom plan year ended' do
      expect(EmployerProfile.organizations_for_plan_year_end(Date.new(calender_year+1, 4, 30)).to_a).to eq [organization1, organization3]
      expect(EmployerProfile.organizations_for_plan_year_end(Date.new(calender_year+1, 5, 1)).to_a).to eq [organization1, organization2, organization3]
    end
  end

  context '.organizations_eligible_for_renewal', dbclean: :after_each do
    it 'should return organizations for renewal' do
      months_prior = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months * -1
      expect(EmployerProfile.organizations_eligible_for_renewal(Date.new(calender_year+1, 2, 1)).to_a).to eq [organization2]
    end
  end
end

describe EmployerProfile, "For General Agency", dbclean: :after_each do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:broker_role) { FactoryGirl.create(:broker_role) }

  context "active_general_agency_account" do
    it "should get active general_agency_account" do
      FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'inactive')
      gaa = FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      expect(employer_profile.general_agency_accounts.count).to eq 2
      expect(employer_profile.active_general_agency_account).to eq gaa
    end
  end

  context "active_general_agency_legal_name" do
    it "with active general_agency_account" do
      FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'inactive')
      gaa = FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      expect(employer_profile.general_agency_accounts.count).to eq 2
      expect(employer_profile.active_general_agency_legal_name).to eq gaa.legal_name
    end

    it "without active general_agency_account" do
      expect(employer_profile.active_general_agency_legal_name).to eq nil
    end
  end

  context "general_agency_profile" do
    it "with active general_agency_account" do
      gaa = FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      expect(employer_profile.general_agency_profile).to eq gaa.general_agency_profile
    end

    it "without active general_agency_account" do
      expect(employer_profile.general_agency_profile).to eq nil
    end
  end

  context "hire_general_agency" do
    it "should get active general_agency_account after hire" do
      employer_profile.hire_general_agency(general_agency_profile, broker_role.id)
      employer_profile.save
      expect(employer_profile.general_agency_profile).to eq general_agency_profile
      expect(employer_profile.active_general_agency_account.present?).to eq true
      expect(employer_profile.active_general_agency_account.broker_role).to eq broker_role
    end
  end

  context "fire_general_agency" do
    it "when without active_general_agency_account" do
      employer_profile.fire_general_agency!
      expect(employer_profile.active_general_agency_account.blank?).to eq true
    end

    it "when with active general_agency_profile" do
      FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      expect(employer_profile.active_general_agency_account.blank?).to eq false
      employer_profile.fire_general_agency!
      expect(employer_profile.active_general_agency_account.blank?).to eq true
    end

    it "when with multiple active general_agency_profile" do
      FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      FactoryGirl.create(:general_agency_account, employer_profile: employer_profile, aasm_state: 'active')
      expect(employer_profile.general_agency_accounts.active.count).to eq 2
      employer_profile.fire_general_agency!
      expect(employer_profile.active_general_agency_account.blank?).to eq true
    end
  end
end

# describe "#advance_day" do
#   let(:start_on) { (TimeKeeper.date_of_record + 60).beginning_of_month }
#   let(:end_on) {start_on + 1.year - 1 }
#   let(:open_enrollment_start_on) { (start_on - 32).beginning_of_month }
#   let(:open_enrollment_end_on) { open_enrollment_start_on + 2.weeks }
#   let(:plan_year) { FactoryGirl.create(:plan_year, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on) }
#   let(:employer_profile) { plan_year.employer_profile }
#   let(:organization) { employer_profile.organization }
#   let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }

#   context "without any published plan years" do
#     it "should stay in the applicant state" do
#       EmployerProfile.advance_day(start_on - 100)
#       expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("applicant")
#     end
#   end

#   context "with a single successfully published a plan year" do
#     before do
#       plan_year.benefit_groups << benefit_group
#       plan_year.publish!
#       expect(plan_year.aasm_state).to eq("published")
#     end

#     it "should be in a registered state" do
#       expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("registered")
#     end

#     it "should be in an enrolling state if day is on or greater than open enrollment start" do
#       EmployerProfile.advance_day(open_enrollment_start_on)
#       expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("enrolling")
#     end

#     context "with an in in valid plan year" do
#       it "should be in an ineligible state" do
#         allow(plan_year).to receive(:is_application_valid?).and_return(false)
#         EmployerProfile.advance_day(open_enrollment_start_on)
#         expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("enrolling")
#       end
#     end
#   end

#   context "with a three plan years that one of which successfully published" do
#     let(:plan_year1) { FactoryGirl.create(:plan_year, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on) }
#     let(:benefit_group2) { FactoryGirl.create(:benefit_group, plan_year: plan_year2) }
#     let(:plan_year2) { FactoryGirl.create(:plan_year, employer_profile: plan_year1.employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on) }
#     let(:benefit_group3) { FactoryGirl.create(:benefit_group, plan_year: plan_year3) }
#     let(:plan_year3) { FactoryGirl.create(:plan_year, employer_profile: plan_year1.employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on) }
#     let(:employer_profile) { plan_year1.employer_profile }

#     before do
#       plan_year1.benefit_groups << benefit_group
#       plan_year2.benefit_groups << benefit_group2
#       plan_year3.benefit_groups << benefit_group3
#       plan_year2.publish!
#       expect(plan_year2.aasm_state).to eq("published")
#     end

#     it "should be in a registered state" do
#       expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("registered")
#     end

#     it "should be in an enrolling state if day is on or greater than open enrollment start" do
#       EmployerProfile.advance_day(open_enrollment_start_on)
#       expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("enrolling")
#     end

#     context "with an in in valid plan year" do
#       it "should be in an ineligible state" do
#         allow(plan_year).to receive(:is_application_valid?).and_return(false)
#         EmployerProfile.advance_day(open_enrollment_start_on)
#         expect(EmployerProfile.find(employer_profile.id).aasm_state).to eq("enrolling")
#       end
#     end
#   end
# end
