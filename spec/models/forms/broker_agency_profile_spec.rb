require "rails_helper"

describe Forms::BrokerAgencyProfile, "given nothing" do

  subject { Forms::BrokerAgencyProfile.new }

  before :each do
    subject.valid?
  end

  it "should validate entity_kind" do
    expect(subject).to have_errors_on(:entity_kind)
  end

  #Auto Generating FEIN for broker agencies
  # it "should validate fein" do
    # expect(subject).to have_errors_on(:fein)
  # end

  it "should validate dob" do
    expect(subject).to have_errors_on(:dob)
  end

  it "should validate first_name" do
    expect(subject).to have_errors_on(:first_name)
  end

  it "should validate last_name" do
    expect(subject).to have_errors_on(:last_name)
  end

  it "should validate legal_name" do
    expect(subject).to have_errors_on(:legal_name)
  end
end


describe Forms::BrokerAgencyProfile, ".save", :dbclean => :after_each do

  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency, fein: "223230323") }
  let(:employer_profile) { FactoryGirl.create(:employer_profile, fein: "333230323") }

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
    }
    }}

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
    Forms::BrokerAgencyProfile.new(attributes)
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

  context 'when broker agency already exists with same FEIN' do

    let(:other_attributes) {
      {
        fein: "223230323"
      }
    }

    before(:each) do
      broker_agency_profile.save
      subject.save
    end

    it 'should raise an error' do
      expect(subject.errors.to_hash[:base]).to include("fein is already in use.")
    end
  end

  context 'when an employer_profile already exists with the same FEIN' do
    let(:other_attributes) {
      { fein: "333230323", npn: "3322323232" }
    }

    before(:each) do
      employer_profile.organization.save!
      subject.save
    end

    it 'should add the broker agency profile to the organization of the employer profile' do
      expect(Organization.where({fein: "333230323"}).first.broker_agency_profile).to be_truthy
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

    it 'should build broker agency from existing record and set person as primary' do
      person = Person.where(first_name: "joseph", last_name: "smith", dob: "10/10/1974").first
      expect(subject.person).to eq(person)

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.broker_agency_profile).to be_truthy
      expect(organization.broker_agency_profile.primary_broker_role).to eq(person.broker_role)
      expect(person.broker_role.broker_agency_profile).to eq(organization.broker_agency_profile)
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

    it 'should build broker agency from new person record and set person as primary' do
      person = Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob).first
      expect(person).to be_truthy
      expect(person.broker_role).to be_truthy
      expect(person.broker_agency_staff_roles.empty?).to be_truthy

      organization = Organization.where(fein: subject.fein).first
      expect(organization).to be_truthy
      expect(organization.broker_agency_profile).to be_truthy
      expect(organization.broker_agency_profile.primary_broker_role).to eq(person.broker_role)
      expect(person.broker_role.market_kind).to eq(attributes[:market_kind])
      expect(person.broker_role.broker_agency_profile).to eq(organization.broker_agency_profile)
    end
  end
end


describe Forms::BrokerAgencyProfile, ".match_or_create_person" do

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
    Forms::BrokerAgencyProfile.new(attributes)
  }


  context 'when email address invalid' do

    it 'should have error on email' do
      broker_agency = Forms::BrokerAgencyProfile.new(attributes.merge({email: "test@email"}))
      broker_agency.valid?
      expect(broker_agency).to have_errors_on(:email)
      expect(broker_agency.errors[:email]).to eq(["test@email is not valid"])
    end
  end

  context 'when more than 1 person matched' do
    before :each do
      2.times { FactoryGirl.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
    end

    it "should raise an exception" do
      expect { subject.match_or_create_person }.to raise_error(Forms::BrokerAgencyProfile::TooManyMatchingPeople)
    end
  end

  context 'when person with same information already present in the system' do
    let(:other_attributes) { {first_name: "larry"}}

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

describe Forms::BrokerAgencyProfile, ".find" do
  let(:organization) {FactoryGirl.create(:organization)}
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }

  before :each do
    @form = Forms::BrokerAgencyProfile.find(broker_agency_profile.id)
  end

  it "should have correct organization info" do
    expect(@form.id).to eq organization.id
    expect(@form.legal_name).to eq organization.legal_name
    expect(@form.dba).to eq organization.dba
    expect(@form.fein).to eq organization.fein
    expect(@form.home_page).to eq organization.home_page
    expect(@form.office_locations).to eq organization.office_locations
  end

  it "should have broker_agency_profile info" do
    expect(@form.entity_kind).to eq broker_agency_profile.entity_kind
    expect(@form.market_kind).to eq broker_agency_profile.market_kind
    expect(@form.languages_spoken).to eq broker_agency_profile.languages_spoken
    expect(@form.working_hours).to eq broker_agency_profile.working_hours
    expect(@form.accept_new_clients).to eq broker_agency_profile.accept_new_clients
  end

  it "should have correct npn" do
    expect(@form.npn).to eq broker_agency_profile.primary_broker_role.try(:npn)
  end
end

describe Forms::BrokerAgencyProfile, '.update_attributes' do
  let(:organization) {FactoryGirl.create(:organization)}
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
  let(:broker_role) { broker_agency_profile.primary_broker_role }
  let(:person) { broker_role.person }

  let(:attributes) { {
    id: organization.id,
    first_name: 'joe',
    last_name: 'smith',
    dob: "2015-06-01",
    email: 'useraccount@gmail.com',
    legal_name: organization.legal_name,
    fein: organization.fein,
    dba: organization.dba,
    home_page: 'dchealth.com',
    entity_kind: broker_agency_profile.entity_kind,
    market_kind: "individual",
    languages_spoken: ["English"],
    working_hours: "0",
    accept_new_clients: "0",
    office_locations_attributes: office_locations
    } }

 let(:office_locations) { {
   "0" => {
     address_attributes: address_attributes,
     phone_attributes: phone_attributes
   }
   }}

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

  before :each do
    @form = Forms::BrokerAgencyProfile.find(broker_agency_profile.id)
    @form.update_attributes(attributes)
  end

  it "should update organization info" do
    organization.reload
    expect(@form.home_page).to eq "dchealth.com"
    expect(organization.home_page).to eq "dchealth.com"
  end

  it "should update broker_agency_profile info" do
    broker_agency_profile.reload
    expect(@form.market_kind).to eq "individual"
    expect(broker_agency_profile.market_kind).to eq "individual"
    expect(broker_agency_profile.languages_spoken).to eq ["English"]
  end

  it "should update person info" do
    person.reload
    expect(@form.first_name).to eq "joe"
    expect(person.first_name).to eq "joe"
  end
end
