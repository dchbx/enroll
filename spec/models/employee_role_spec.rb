require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe EmployeeRole do
  let(:person) {Person.new}
  subject {EmployeeRole.new(:person => person)}

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
  let(:hbx_id) {"555553443"}
  let(:ssn) {"012345678"}
  let(:dob) {Date.new(2009, 2, 5)}
  let(:gender) {"female"}

  let(:person) {Person.new(
      :hbx_id => hbx_id,
      :ssn => ssn,
      :dob => dob,
      :gender => gender
  )}

  subject {EmployeeRole.new(:person => person)}

  before do
    subject.valid?
  end

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


describe ".coverage_effective_on" do

  context 'when both active and renewal benefit groups present', dbclean: :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"

    let(:renewal_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
    let(:current_effective_date)  { renewal_effective_date.prev_year }
    let(:employer_profile) { abc_profile }
    let(:organization) { abc_organization }
    let(:hired_on) {TimeKeeper.date_of_record.beginning_of_month}

    let!(:census_employees) {
      FactoryBot.create :benefit_sponsors_census_employee, :owner, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship
      FactoryBot.create :benefit_sponsors_census_employee, employer_profile: employer_profile, hired_on: hired_on, benefit_sponsorship: organization.active_benefit_sponsorship
    }

    let(:ce) {employer_profile.census_employees.non_business_owner.first}

    let(:employee_role) {
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      FactoryBot.create(:benefit_sponsors_employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    }

    context 'when called with benefit group' do
      let(:renewal_benefit_group) {employer_profile.renewal_benefit_application.benefit_packages.first}

      it 'should calculate effective date from renewal benefit group' do
        expect(employee_role.coverage_effective_on(current_benefit_group: renewal_benefit_group)).to eq renewal_benefit_group.start_on
      end
    end

    context 'when called without benefit group' do

      it 'should calculate effective date based on active benefit group' do
        expect(employee_role.coverage_effective_on).to eq hired_on
      end
    end
  end
end

describe EmployeeRole, dbclean: :around_each do
  let(:ssn) {"987654321"}
  let(:dob) {36.years.ago.to_date}
  let(:gender) {"female"}
  let(:hired_on) {10.days.ago.to_date}
  let!(:rating_area) {FactoryBot.create_default :benefit_markets_locations_rating_area}
  let!(:service_area) {FactoryBot.create_default :benefit_markets_locations_service_area}
  let(:benefit_sponsorship) {employer_profile.add_benefit_sponsorship}

  describe "built" do
    let(:address) {FactoryBot.build(:address)}
    let(:saved_person) {FactoryBot.create(:person, first_name: "Annie", last_name: "Lennox", addresses: [address])}
    let(:new_person) {FactoryBot.build(:person, first_name: "Carly", last_name: "Simon")}
    let(:site) {FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :dc, :as_hbx_profile)}

    let(:organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                           :with_aca_shop_dc_employer_profile_initial_application,
                                           site: site
    )}
    let(:employer_profile) {organization.employer_profile}

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

    before do
      benefit_sponsorship
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
  it 'properly intantiates the class using a new person' # do
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

describe EmployeeRole, dbclean: :around_each do
  let(:person_created_at) {10.minutes.ago}
  let(:person_updated_at) {8.minutes.ago}
  let(:employee_role_created_at) {9.minutes.ago}
  let(:employee_role_updated_at) {7.minutes.ago}
  let(:ssn) {"019283746"}
  let(:dob) {45.years.ago.to_date}
  let(:hired_on) {2.years.ago.to_date}
  let(:gender) {"male"}
  let!(:rating_area) {FactoryBot.create_default :benefit_markets_locations_rating_area}
  let!(:service_area) {FactoryBot.create_default :benefit_markets_locations_service_area}
  let(:site) {FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :cca, :as_hbx_profile)}

  context "when created" do
    # let(:employer_profile) { FactoryBot.create(:employer_profile) }

    let(:organization) {
      FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                         :with_aca_shop_cca_employer_profile_initial_application,
                         site: site
      )}

    let(:employer_profile) {organization.employer_profile}

    let(:person) {
      FactoryBot.create(:person,
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
      let(:middle_name) {"Albert"}
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
      let(:new_hired_on) {10.days.ago.to_date}

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
    let(:match_size) {5}
    let(:non_match_size) {3}
    # let(:match_employer_profile)      { FactoryBot.create(:employer_profile) }
    # let(:non_match_employer_profile)  { FactoryBot.create(:employer_profile) }
    let(:site) {FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :dc, :as_hbx_profile)}
    let!(:organization1) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile)}
    let(:match_employer_profile) {organization1.employer_profile}
    let(:match_benefit_sponsorship) {match_employer_profile.add_benefit_sponsorship}
    let!(:organization2) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile)}
    let(:non_match_employer_profile) {organization2.employer_profile}
    let(:non_match_benefit_sponsorship) {non_match_employer_profile.add_benefit_sponsorship}
    let!(:match_employee_roles) {FactoryBot.create_list(:employee_role, 5, employer_profile: match_employer_profile)}
    let!(:non_match_employee_roles) {FactoryBot.create_list(:employee_role, 3, employer_profile: non_match_employer_profile)}
    let(:first_match_employee_role) {match_employee_roles.first}
    let(:first_non_match_employee_role) {non_match_employee_roles.first}
    let(:ee_ids) {[first_match_employee_role.id, first_non_match_employee_role.id]}

    before do
      match_benefit_sponsorship
      non_match_benefit_sponsorship
      match_employee_roles.each do |ee|
        census_employee = FactoryBot.create(:census_employee, employer_profile: match_employer_profile, benefit_sponsorship: match_employer_profile.benefit_sponsorships.first, employee_role_id: ee.id)
        ee.update_attributes(census_employee_id: census_employee.id)
      end
    end

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


describe EmployeeRole, dbclean: :around_each do

  # let(:employer_profile)          { FactoryBot.create(:employer_profile) }
  let(:calendar_year) {TimeKeeper.date_of_record.year}
  let(:middle_of_prev_year) {Date.new(calendar_year - 1, 6, 10)}

  let(:site) {FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :dc, :as_hbx_profile)}

  let(:organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                         :with_aca_shop_dc_employer_profile_initial_application,
                                         site: site
  )}

  let(:employer_profile) {organization.employer_profile}
  let(:benefit_application) {organization.active_benefit_sponsorship.current_benefit_application}
  let(:benefit_package) {benefit_application.benefit_packages.first}

  let!(:rating_area) {FactoryBot.create_default :benefit_markets_locations_rating_area}
  let!(:service_area) {FactoryBot.create_default :benefit_markets_locations_service_area}
  let!(:benefit_sponsorship) {employer_profile.add_benefit_sponsorship}

  let(:benefit_group_assignment) {
    BenefitGroupAssignment.create({
                                      census_employee: census_employee,
                                      # benefit_group: plan_year.benefit_groups.first,
                                      benefit_package: benefit_package,
                                      start_on: benefit_package.start_on
                                  })
  }

  let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee,
                                            benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                                            employer_profile: employer_profile,
                                            created_at: middle_of_prev_year,
                                            updated_at: middle_of_prev_year,
                                            hired_on: middle_of_prev_year
  )}

  let(:person) {FactoryBot.create(:person,
                                   first_name: census_employee.first_name,
                                   last_name: census_employee.last_name,
                                   dob: census_employee.dob,
                                   ssn: census_employee.ssn
  )}

  let(:employee_role) {
    person.employee_roles.create(
        employer_profile: employer_profile,
        hired_on: census_employee.hired_on,
        census_employee_id: census_employee.id
    )
  }

  let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
  let(:plan_year_start_on) {benefit_application.start_on}
  let(:plan_year_end_on) {benefit_application.end_on}
  let(:open_enrollment_start_on) {benefit_application.open_enrollment_start_on}
  let(:open_enrollment_end_on) {benefit_application.open_enrollment_end_on}

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  # let!(:plan_year) {

  #   py = FactoryBot.create(:plan_year,
  #     start_on: plan_year_start_on,
  #     end_on: plan_year_end_on,
  #     open_enrollment_start_on: open_enrollment_start_on,
  #     open_enrollment_end_on: open_enrollment_end_on,
  #     employer_profile: employer_profile
  #     )

  #   blue = FactoryBot.build(:benefit_group, title: "blue collar", plan_year: py)
  #   white = FactoryBot.build(:benefit_group, title: "white collar", plan_year: py)
  #   py.benefit_groups = [blue, white]
  #   py.save
  #   py.update_attributes(:aasm_state => 'published')
  #   py
  # }


  before do
    # allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
    # allow(employee_role).to receive(:benefit_group).and_return(benefit_package)
    # census_employee.update_attributes({employee_role_id: employee_role.id})
    # allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
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
      let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee,
                                                benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                                                employer_profile: employer_profile,
                                                created_at: (plan_year_start_on + 10.days),
                                                updated_at: (plan_year_start_on + 10.days),
                                                hired_on: (plan_year_start_on + 10.days)
      )}

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 15.days)
      end

      it "should return true" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_truthy
      end
    end


    context 'when new roster entry enrollment period available' do
      let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee,
                                                benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                                                employer_profile: employer_profile,
                                                created_at: (plan_year_start_on + 10.days),
                                                updated_at: (plan_year_start_on + 10.days),
                                                hired_on: middle_of_prev_year
      )}

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 15.days)
      end

      it "should return true" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_truthy
      end
    end

    context 'when outside new hire enrollment period and employer open enrolment' do
      let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee,
                                                benefit_sponsorship: employer_profile.active_benefit_sponsorship,
                                                employer_profile: employer_profile,
                                                created_at: (plan_year_start_on + 10.days),
                                                updated_at: (plan_year_start_on + 10.days),
                                                hired_on: (plan_year_start_on + 10.days)
      )}

      before do
        TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 55.days)
      end

      it "should return false" do
        expect(employee_role.is_eligible_to_enroll_without_qle?).to be_falsey
      end
    end
  end

  context "can_select_coverage?" do
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role)}

    it "should return true when hired_on is less than two monthes ago" do
      employee_role.hired_on = TimeKeeper.date_of_record - 15.days
      expect(employee_role.can_select_coverage?).to eq true
    end

    it "should return false when hired_on is more than two monthes ago" do
      employee_role.hired_on = TimeKeeper.date_of_record - 75.days
      expect(employee_role.can_select_coverage?).to eq false
    end
  end

  context "is_cobra_status?" do
    let(:employee_role) {FactoryBot.build(:benefit_sponsors_employee_role)}
    let(:census_employee) {FactoryBot.build(:benefit_sponsors_census_employee)}

    it "should return false when without census_employee" do
      allow(employee_role).to receive(:census_employee).and_return nil
      expect(employee_role.is_cobra_status?).to be_falsey
    end

    context "with census_employee" do
      before :each do
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      it "should return cobra state of census_employee" do
        expect(employee_role.is_cobra_status?).to eq census_employee.is_cobra_status?
      end
    end
  end
end

describe '#fetch_benefit_applications_for_date', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person, :with_employee_role)}
  let(:employee_role) {person.employee_roles.first}
  let(:plan_year) { initial_application }
  let(:employer_profile) { abc_profile }

  context '#prior_plan_year_sep feature turned on' do

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_sep).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:employer_profile).and_return(abc_profile)
      allow(employer_profile).to receive(:plan_years).and_return(plan_year)
    end

    context 'when effective date does not fall under PY' do
      it "not return any benefit applications" do
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
        allow(plan_year).to receive(:end_on).and_return((TimeKeeper.date_of_record + 1.year).beginning_of_month - 1.day)
        expect(employee_role.fetch_benefit_applications_for_date(TimeKeeper.date_of_record - 5.days)).to eq([])
      end
    end

    context 'when effective date falls under PY' do
      it "return benefit applications" do
        allow(plan_year).to receive(:aasm_state).and_return(:expired)
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
        allow(plan_year).to receive(:end_on).and_return((TimeKeeper.date_of_record + 1.year).beginning_of_month - 1.day)
        expect(employee_role.fetch_benefit_applications_for_date(TimeKeeper.date_of_record + 5.days)).to eq([plan_year])
      end
    end
  end

  context '#prior_plan_year_sep feature turned off' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_sep).and_return(false)
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:employer_profile).and_return(abc_profile)
      allow(employer_profile).to receive(:plan_years).and_return(plan_year)
    end

    context 'when PY is expired or terminated' do
      it "not return any benefit applications when py" do
        plan_year.update_attributes(aasm_state: :expired)
        expect(employee_role.fetch_benefit_applications_for_date(TimeKeeper.date_of_record + 5.days)).to eq([])
      end

      it "not return any benefit applications" do
        plan_year.update_attributes(aasm_state: :terminated)
        expect(employee_role.fetch_benefit_applications_for_date(TimeKeeper.date_of_record - 5.days)).to eq([])
      end
    end

    context 'when PY is active' do
      it "return benefit applications" do
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
        allow(plan_year).to receive(:end_on).and_return((TimeKeeper.date_of_record + 1.year).beginning_of_month - 1.day)
        expect(employee_role.fetch_benefit_applications_for_date(TimeKeeper.date_of_record + 5.days)).to eq([plan_year])
      end
    end
  end
end

describe "#benefit_package", dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)}
  let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
  let(:person) {FactoryBot.create(:person, :with_employee_role)}
  let(:employee_role) {person.employee_roles.first}
  let(:census_employee) {FactoryBot.create(:census_employee, employer_profile: abc_profile, benefit_sponsorship: benefit_sponsorship, employee_role_id: employee_role.id)}
  let(:renewal_state) {:active}
  let(:predecessor_state) {:expired}

  before do
    employee_role.update_attributes(census_employee_id: census_employee.id)
  end

  context "plan shop through qle and having active & renewal plan years" do

    it "should return the active benefit group if sep effective date covers active plan year" do
      sep.update_attribute(:effective_on, benefit_package.start_on + 2.days)
      allow(family).to receive(:current_sep).and_return sep
      allow(predecessor_application).to receive(:benefit_packages).and_return census_employee.benefit_group_assignments.first.benefit_package
      expect(employee_role.benefit_package(qle: true)).to eq predecessor_application.benefit_groups
    end

    it "should return the renewal benefit group if sep effective date covers renewal plan year" do
      sep.update_attribute(:effective_on, benefit_package.start_on + 2.days)
      expect(employee_role.benefit_package(qle: true)).to eq benefit_package
    end
  end

  context "plan shop through qle and having active & expired plan years", dbclean: :around_each do

    before do
      benefit_sponsorship
      active_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :active).first.benefit_packages.first
      expired_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :expired).first.benefit_packages.first
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: active_benefit_group, start_on: active_benefit_group.benefit_application.start_on)
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: expired_benefit_group, start_on: expired_benefit_group.benefit_application.start_on)
      sep.update_attribute(:effective_on, expired_benefit_group.benefit_application.end_on - 7.days)
    end
    it "should return the expired benefit group if sep effective date covers expired plan year & has expired benefit group assignment" do
      expired_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :expired).first.benefit_packages.first
      expect(employee_role.benefit_package(qle: true)).to eq expired_benefit_group
    end

    it "should return the active benefit group if sep effective date covers expired plan year if EE was not assigned to expired benefit group" do
      active_benefit_group = abc_organization.employer_profile.benefit_applications.where(aasm_state: :active).first.benefit_packages.first
      sep.update_attribute(:effective_on, active_benefit_group.benefit_application.end_on - 7.days)
      expect(employee_role.benefit_package(qle: true)).to eq active_benefit_group
    end
  end
end

describe EmployeeRole do

  context 'is_dental_offered?', dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"

    let(:product_kinds) {[:health, :dental]}
    let(:person) {FactoryBot.create(:person)}
    let(:employee_role) { FactoryBot.create(:employee_role, person: person, benefit_sponsors_employer_profile_id: abc_profile.id)}

    context "EE for New ER who's offering Dental trying to purchase coverage during open enrollment" do
      include_context "setup initial benefit application"

      let(:dental_sponsored_benefit) {true}
      let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }

      context 'When benefit package assigned' do
        let(:census_employee) {FactoryBot.create(:census_employee, employer_profile: abc_profile, benefit_sponsorship: benefit_sponsorship, employee_role_id: employee_role.id)}

        before do
          employee_role.update_attributes(census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id, employer_profile_id: nil)
        end

        it 'should retrun true' do
          expect(employee_role.is_dental_offered?).to be_truthy
        end
      end
    end

    context "EE for Renewing ER who's offering Dental trying to purchase coverage during open enrollment" do
      include_context "setup renewal application"
      let(:renewal_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:renewal_state) {:enrollment_eligible }
      let(:dental_sponsored_benefit) {true}

      context 'When benefit package assigned' do
        let(:census_employee) {FactoryBot.create(:census_employee, employer_profile: abc_profile, benefit_sponsorship: benefit_sponsorship, employee_role_id: employee_role.id, hired_on: TimeKeeper.date_of_record)}

        before do
          employee_role.update_attributes(census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id, employer_profile_id: nil)
        end

        it 'should retrun true' do
          expect(employee_role.is_dental_offered?).to be_truthy
        end
      end
    end

    context 'default contact_method' do
      it { expect(FactoryBot.build(:employee_role).contact_method).to eq(Settings.aca.shop_market.employee.default_contact_method) }
    end
  end
end
