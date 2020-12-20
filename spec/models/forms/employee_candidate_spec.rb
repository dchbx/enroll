require "rails_helper"

describe Forms::EmployeeCandidate do
  let(:subject) { Forms::EmployeeCandidate.new({:ssn => "1236789"})}

  before :each do
    subject.valid?
  end

  it "should have error on dob" do
    expect(subject).to have_errors_on(:dob)
  end

  it "should have errors on gender" do
    expect(subject).to have_errors_on(:gender)
  end

  it "should have errors on the missing names" do
    expect(subject).to have_errors_on(:last_name)
    expect(subject).to have_errors_on(:first_name)
  end

  it "should have errors on the ssn" do
    expect(subject).to have_errors_on(:ssn)
  end
end

describe Forms::EmployeeCandidate, "asked to match a census employee" do
  let(:fake_plan_year) { instance_double("PlanYear") }
  let(:census_employee) { instance_double("CensusEmployee", :first_name => "Tom", :last_name => "Baker", :gender => "male", :ssn => "123456789", :dob => Date.new(2012, 10, 12), :aasm_state => "eligible", :eligible? => true) }
  let(:fake_employer) { instance_double("EmployerProfile", :census_employees => [census_employee], :plan_years => [fake_plan_year]) }
  let(:fake_org) { instance_double("Organization", :employer_profile => fake_employer) }

  subject {
    Forms::EmployeeCandidate.new({
                                     :dob => "2012-10-12",
                                     :ssn => "123-45-6789",
                                     :first_name => "Tom",
                                     :last_name => "Baker",
                                     :gender => "male",
                                     :is_applying_coverage => false
                                 })
  }

  let(:search_params) { {
      :dob => Date.new(2012, 10, 12),
      :ssn => "123456789"
  } }

  it "should return nothing if that employee does not exist" do
    allow(Organization).to receive(:where).and_return([])
    expect(subject.match_census_employees).to be_empty
  end

  context "and the plan year is not allowing matching" do
    before do
      allow(fake_plan_year).to receive(:is_eligible_to_match_census_employees?).and_return(false)
      allow(Organization).to receive(:where).and_return([fake_org])
    end

    it "should return nothing" do
      expect(subject.match_census_employees).to be_empty
    end

    it "should be valid" do
      expect(subject.valid?).to be_truthy
    end
  end

  context "and the plan year is allowing matching" do
    before do
      allow(CensusEmployee).to receive(:matchable).and_return([census_employee])
    end

    it "should return the census employee when one is matched by dob and ssn" do
      expect(subject.match_census_employees).to eq [census_employee]
    end

    it "should be valid" do
      expect(subject.valid?).to be_truthy
    end
  end
end

describe Forms::EmployeeCandidate, "asked to match a person" do

  subject {
    Forms::EmployeeCandidate.new({
                                     :dob => "2012-10-12",
                                     :ssn => "123-45-6789",
                                     :first_name => "yo",
                                     :last_name => "guy",
                                     :gender => "male",
                                     :user_id => 20,
                                     :is_applying_coverage => false
                                 })
  }

  let(:search_params) { {
      :dob => Date.new(2012, 10, 12),
      :encrypted_ssn => Person.encrypt_ssn("123456789")
  } }

  let(:user) { nil }
  let(:person) { double(user: user) }

  let(:people) { [person] }

  it "should return nothing if that person does not exist" do
    allow(Person).to receive(:where).and_return([])
    expect(subject.match_person).to be_nil
  end

  context "who does not have a user account associated" do
    it "should return the person when one is matched by dob and ssn" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      expect(subject.match_person).to eq person
    end
  end

  context "who does have a user acccount associated with current user" do
    let(:user) { double(id: 20, has_hbx_staff_role?: false) }
    let(:person) { double(user: user) }

    it "should return the person when one is matched by dob and ssn" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      allow(User).to receive(:find).with(user.id).and_return user
      expect(subject.valid?).to be_truthy
      expect(subject.match_person).to eq person
    end
  end

  context "who does have a user acccount associated" do
    let(:user) { double(id: 12, has_hbx_staff_role?: false) }
    let(:person) { double(user: user) }

    it "should have an error that the person is associted with another use" do
      allow(Person).to receive(:where).with(search_params).and_return(people)
      allow(User).to receive(:find).and_return user
      subject.valid?
      expect(subject).to have_errors_on(:base)
    end
  end

  context "future date of birth" do
    let(:user) { double(id: 12, has_hbx_staff_role?: false) }
    it "gives error on dob" do
      allow(User).to receive(:find).and_return user
      subject.dob = TimeKeeper.date_of_record + 20.years
      expect(subject.valid?).to be_falsey
      expect(subject).to have_errors_on(:dob)
    end
  end
end

describe "match a person in db" do
  let(:subject) {
    Forms::EmployeeCandidate.new({
                                     :dob => search_params.dob,
                                     :ssn => search_params.ssn,
                                     :first_name => search_param_name.first_name,
                                     :last_name => search_param_name.last_name,
                                     :gender => "male",
                                     :user_id => 20,
                                     :is_applying_coverage => false
                                 })
  }

  let(:search_params) { double(dob: db_person.dob.strftime("%Y-%m-%d"), ssn: db_person.ssn, )}
  let(:search_param_name) { double( first_name: db_person.first_name, last_name: db_person.last_name)}

  after(:each) do
    DatabaseCleaner.clean
  end

  context "with a person with a first name, last name, dob and no SSN" do
    let(:db_person) { Person.create!(first_name: "Joe", last_name: "Kramer", dob: "1993-03-30", ssn: '')}

    it 'matches the person by last_name, first name and dob if there is no ssn' do
      expect(subject.match_person).to eq db_person
    end

    it 'matches the person ingoring case' do
      subject.first_name.upcase!
      subject.last_name.downcase!
      expect(subject.match_person).to eq db_person
    end

    context "with a person who has no ssn but an employer staff role", dbclean: :after_each do
      let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role) { EmployerStaffRole.create(person: db_person, benefit_sponsor_employer_profile_id: employer_profile.id) }

      it 'matches person by last name, first name and dob' do
        db_person.employer_staff_roles << employer_staff_role
        db_person.save!
        allow(search_params).to receive(:ssn).and_return("517991234")
        expect(subject.match_person).to eq db_person
        expect(subject.match_person.gender).not_to eq nil
        expect(subject.match_person.ssn).not_to eq nil
      end
    end
  end

  context "with a person with a first name, last name, dob and ssn" do
    let(:db_person) { Person.create!(first_name: "Jack",   last_name: "Weiner",   dob: "1943-05-14", ssn: "517994321")}

    it 'matches the person by ssn and dob' do
      expect(subject.match_person).to eq db_person
    end

    it 'does not find the person if payload has a different ssn from the person' do
      subject.ssn = "888891234"
      expect(subject.match_person).to eq nil
    end
  end
end
