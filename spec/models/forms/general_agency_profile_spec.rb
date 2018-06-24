require "rails_helper"

describe Forms::GeneralAgencyProfile, "given nothing" do
  subject { Forms::GeneralAgencyProfile.new }

  before :each do
    subject.valid?
  end

  it "should validate market_kind" do
    expect(subject).to have_errors_on(:market_kind)
  end

  it "should validate email" do
    expect(subject).to have_errors_on(:email)
  end
end

describe Forms::BrokerAgencyProfile, ".save", :dbclean => :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }

  let(:attributes) { {
    first_name: 'joe',
    last_name: 'smith',
    dob: "2015-06-01",
    email: 'useraccount@gmail.com',
    npn: "8422323232",
    legal_name: 'useragency',
    fein: "223232323",
    entity_kind: "c_corporation",
    market_kind: "individual",
    working_hours: "0",
    accept_new_clients: "0",
    office_locations_attributes: office_locations
    }.merge(other_attributes) }

  let(:other_attributes) { { } }

  let(:office_locations) { {
    "0" => {
      address_attributes: address_attributes,
      phone_attributes: phone_attributes
    }}}

  let(:address_attributes) {
    {
      kind: "primary",
      address_1: "99 N ST",
      city: "washignton",
      state: "dc",
      zip: "20006"
    }
  }

  let(:phone_attributes) {
    {
      kind: "phone main",
      area_code: "202",
      number: "324-2232"
    }
  }

  subject {
    Forms::GeneralAgencyProfile.new(attributes)
  }

  context 'when multiple users exists with same personal information' do
    let(:other_attributes) { {
      first_name: "steve",
      last_name: "smith",
      dob: "1974-10-10"
      }}

    before(:each) do
      2.times { FactoryGirl.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base]).to include("too many people match the criteria provided for your identity.  Please contact HBX.")
    end
  end

  context 'when general agency already exists with same FEIN' do
    let(:general_agency) { FactoryGirl.create(:general_agency_with_organization) }
    let(:other_attributes) {
      {
        fein: general_agency.fein
      }
    }

    before(:each) do
      general_agency.save
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base]).to include("organization has already been created.")
    end
  end

  context "when for staff role without general_agency_profile_id" do
    let(:other_attributes) {
      {
        applicant_type: "staff",
        general_agency_profile_id: ""
      }
    }

    before(:each) do
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base].to_s).to include("General agency can not be blank")
    end
  end

  context 'when existing user matched with same personal information' do
    let(:other_attributes) { {
      first_name: "joseph",
      last_name: "smith",
      dob: "1974-10-10"
      }}

    before(:each) do
      FactoryGirl.create(:person, first_name: "joseph", last_name: "smith", dob: "10/10/1974")
      subject.save
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it 'should build general agency from existing record and set person as primary' do
      person = Person.where(first_name: "joseph", last_name: "smith", dob: "10/10/1974").first
      expect(subject.person).to eq(person)

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.general_agency_profile).to be_truthy
      expect(person.general_agency_staff_roles.last.general_agency_profile).to eq(organization.general_agency_profile)
    end
  end

  context 'when person details not matched with existing people' do
    let(:other_attributes) { {
      first_name: 'kevin',
      email: "useraccount2@gmail.com",
      npn: "8022303232",
      fein: "223232300"
      }}

    before(:each) do
      subject.save
    end

    it 'should build general agency from new person record' do
      person = Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob).first
      expect(person).to be_truthy
      expect(person.general_agency_staff_roles).to be_truthy

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.general_agency_profile).to be_truthy
      expect(person.general_agency_staff_roles.last.general_agency_profile).to eq(organization.general_agency_profile)
    end
  end

  context "validate_duplicate_npn" do
    let(:staff) { FactoryGirl.create(:general_agency_staff_role) }
    let(:other_attributes) { {
      first_name: 'kevin',
      email: "useraccount2@gmail.com",
      npn: staff.npn,
      fein: "223232300"
      }}

    before(:each) do
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base].to_s).to include("NPN has already been claimed by another general agency staff. Please contact HBX-Customer Service - Call (855) 532-5465.")
    end
  end
end


describe Forms::GeneralAgencyProfile, ".match_or_create_person", :dbclean => :after_each do
  let(:attributes) { {
    first_name: "steve",
    last_name: "smith",
    email: "example@email.com",
    dob: "1974-10-10",
    npn: "8422323232",
    legal_name: 'useragency',
    fein: "223232323",
    entity_kind: "c_corporation",
    market_kind: "individual"
  }.merge(other_attributes)}

  let(:other_attributes) { {} }

  subject {
    Forms::GeneralAgencyProfile.new(attributes)
  }

  context 'when email address invalid' do
    it 'should have error on email' do
      general_agency = Forms::GeneralAgencyProfile.new(attributes.merge({email: "test@email"}))
      general_agency.valid?
      expect(general_agency).to have_errors_on(:email)
      expect(general_agency.errors[:email]).to eq(["test@email is not valid"])
    end
  end

  context 'when more than 1 person matched' do
    before :each do
      2.times { FactoryGirl.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
    end

    it "should raise an exception" do
      expect { subject.match_or_create_person }.to raise_error(Forms::GeneralAgencyProfile::TooManyMatchingPeople)
    end
  end

  context 'when person with same information already present in the system' do
    let(:other_attributes) { {first_name: "larry"}}

    after(:all) do
      DatabaseCleaner.clean
    end

     before :each do
      FactoryGirl.create(:person, first_name: "larry", last_name: "smith", dob: "10/10/1974")
      subject.match_or_create_person
    end

    it "should build person with existing record" do
      person = Person.where(first_name: "larry", last_name: "smith", dob: "10/10/1974").first
      expect(subject.person).to eq(person)
    end
  end

  context 'when person not matched in the system' do
    let(:other_attributes) { {
      first_name: "robin",
      last_name: "smith",
      email: "example@email.com",
      dob: "1978-08-10"
      } }

    before :each do
      subject.match_or_create_person
    end

    it "should build new person" do
      expect(subject.person).to be_truthy
      expect(subject.person.first_name).to eq(attributes[:first_name])
      expect(subject.person.last_name).to eq(attributes[:last_name])
      expect(subject.person.dob).to eq(subject.dob)
    end

    it "should add work email address to the person" do
      expect(subject.person.emails).not_to be_empty
      expect(subject.person.emails[0].kind).to eq('work')
      expect(subject.person.emails[0].address).to eq(attributes[:email])
    end
  end
end

describe Forms::GeneralAgencyProfile, ".find", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile, :with_staff) }
  let(:organization) { general_agency_profile.organization }

  before :each do
    @form = Forms::GeneralAgencyProfile.find(general_agency_profile.id)
  end

  it "should have correct organization info" do
    expect(@form.id).to eq organization.id
    expect(@form.legal_name).to eq organization.legal_name
    expect(@form.dba).to eq organization.dba
    expect(@form.fein).to eq organization.fein
    expect(@form.home_page).to eq organization.home_page
    expect(@form.office_locations).to eq organization.office_locations
  end

  it "should have general_agency_profile info" do
    expect(@form.entity_kind).to eq general_agency_profile.entity_kind
    expect(@form.market_kind).to eq general_agency_profile.market_kind
    expect(@form.languages_spoken).to eq general_agency_profile.languages_spoken
    expect(@form.working_hours).to eq general_agency_profile.working_hours
    expect(@form.accept_new_clients).to eq general_agency_profile.accept_new_clients
  end

  it "should have correct npn" do
    expect(@form.npn).to eq general_agency_profile.primary_staff.npn
  end
end
