require "rails_helper"

describe Forms::BrokerCandidate do

  let(:broker_role) { FactoryBot.build(:broker_role, npn: '234567890') }
  let(:person_obj) { FactoryBot.create(:person, :with_ssn, first_name: "steve", last_name: "smith", dob: "10/10/1974") }

  let(:attributes) { {
    broker_applicant_type: "broker", 
    first_name: "firstname", 
    last_name: "lastname", 
    dob: "1993-06-03",
    email: "useraccount@gmail.com", 
    npn: "234567895",
    broker_agency_id: @broker_agency_profile.id,
    market_kind: 'shop',
    languages_spoken: ['en'],
    working_hours: true,
    accept_new_clients: false
    }.merge(other_attributes) }

  let(:other_attributes) { { } }

  subject {
    Forms::BrokerCandidate.new(attributes)
  }

  before (:all) do
    @broker_agency_profile = FactoryBot.create(:broker_agency).broker_agency_profile
  end

  it "should have addresses when initialize" do
    broker = Forms::BrokerCandidate.new()
    expect(broker.addresses.class).to eq Array
    expect(broker.addresses.first.kind).to eq 'home'
  end

  context 'when email address invalid' do 

    it 'should have error on email' do 
      broker = Forms::BrokerCandidate.new(attributes.merge({email: "test@email"}))
      broker.valid?
      expect(broker).to have_errors_on(:email)
      expect(broker.errors[:email]).to eq(["test@email is not valid"])
    end
  end

  context 'when data missing' do 

    let(:attributes) { { broker_applicant_type: 'staff' } }

    before :each do
      subject.valid?
    end

    it "should validate dob" do
      expect(subject).to have_errors_on(:dob)
    end

    it "should validate first_name" do
      expect(subject).to have_errors_on(:first_name)
    end

    it "should validate last_name" do
      expect(subject).to have_errors_on(:last_name)
    end

    it "should validate email" do
      expect(subject).to have_errors_on(:email)
    end
  end

  describe 'Broker NPN validations' do

    before :each do
      subject.valid?
    end

    context 'when Applicant is a broker and NPN is missing' do
      let(:attributes) { { broker_applicant_type: 'broker' } }

      it "should raise an error" do
        expect(subject).to have_errors_on(:npn)
      end
    end

    context 'when Applicant is broker and NPN is present' do
      let(:attributes) { { npn: '344232423', broker_applicant_type: 'broker' } }

      it "should pass" do
        expect(subject).not_to have_errors_on(:npn)
      end
    end

    context 'when Applicant is a broker agency staff member and NPN is missing' do
      let(:attributes) { { broker_applicant_type: 'staff' } }

      it "should skip NPN validation" do
        expect(subject).not_to have_errors_on(:npn)
      end
    end
  end

  context 'when Broker enters a duplicate NPN' do

    let(:other_attributes) { {
      npn: "234567890"
      } }

    it "should raise an error" do
      person_obj.broker_role = broker_role
      subject.valid?
      expect(subject.errors.to_hash[:base]).to include("NPN has already been claimed by another broker. Please contact HBX.")
    end
  end

  describe "Broker Agency validations" do 

    before :each do 
      subject.valid?
    end

    context 'when broker agency missing' do
      let(:other_attributes) { {
        broker_agency_id: nil
        } }

      it "should raise an error" do 
        expect(subject.errors.to_hash[:base]).to include("Please select your broker agency.")
      end
    end

    context 'when broker agency not found in database' do
      let(:other_attributes) { {
        broker_agency_id: "55929d867261670838550000"
        } }

      it "should raise an error" do 
        expect(subject.errors.to_hash[:base]).to include("Unable to locate the broker agnecy. Please contact HBX.")
      end
    end
  end

  describe ".save" do

    context 'when multiple people matched with the entered personal information' do
      let(:other_attributes) { {
        first_name: "john",
        last_name: "smith",
        dob: "1974-10-10",
        }}
      
      before(:each) do
        2.times { FactoryBot.create(:person, :with_ssn, first_name: "john", last_name: "smith", dob: "10/10/1974") }
        subject.save
      end

      it 'should raise an error' do
        expect(subject.errors.to_hash[:base]).to include("too many people match the criteria provided for your identity.  Please contact HBX-Customer Service - Call (855) 532-5465.")
      end
    end

    describe 'for broker applicant' do

      context 'when no person match found' do
        it 'should save new person with broker role' do
          expect(Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob)).to be_empty
          subject.save
          person = Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob).first
          expect(person).to be_truthy
          expect(person.broker_role).not_to be_falsey
          expect(person.broker_agency_staff_roles).to be_empty
          expect(person.broker_role.npn).to eq(attributes[:npn])
          expect(person.broker_role.broker_agency_profile_id).to eq(attributes[:broker_agency_id])
          expect(person.broker_role.market_kind).to eq attributes[:market_kind]
          expect(person.broker_role.languages_spoken).to eq attributes[:languages_spoken]
          expect(person.broker_role.working_hours).to eq attributes[:working_hours]
          expect(person.broker_role.accept_new_clients).to eq attributes[:accept_new_clients]
        end
      end

      context 'when matched with existing person' do
        let(:other_attributes) { {
          first_name: "kevin",
          npn: '333232324'
          }}

        before (:each) do 
          FactoryBot.create(:person, :with_ssn, first_name: 'kevin', last_name: subject.last_name, dob: subject.dob)
        end

        it 'should update existing person with broker role' do
          expect(Person.where(first_name: 'kevin', last_name: subject.last_name, dob: subject.dob)).not_to be_empty
          subject.save
          person = Person.where(first_name: 'kevin', last_name: subject.last_name, dob: subject.dob).first
          expect(person).to be_truthy
          expect(person.broker_role).to be_truthy
          expect(person.broker_agency_staff_roles).to be_empty
          expect(person.broker_role.npn).to eq(attributes[:npn])
          expect(person.broker_role.broker_agency_profile_id).to eq(attributes[:broker_agency_id])
          expect(person.broker_role.market_kind).to eq attributes[:market_kind]
          expect(person.broker_role.languages_spoken).to eq attributes[:languages_spoken]
          expect(person.broker_role.working_hours).to eq attributes[:working_hours]
          expect(person.broker_role.accept_new_clients).to eq attributes[:accept_new_clients]
        end
      end
    end

    describe 'for broker agency staff member' do

      context 'when no person match found' do
        let(:other_attributes) { {
          first_name: "james", 
          broker_applicant_type: "staff"
          }}

        it 'should save new person with broker staff role' do
          expect(Person.where(first_name: "james", last_name: subject.last_name, dob: subject.dob)).to be_empty
          subject.save
          person = Person.where(first_name: "james", last_name: subject.last_name, dob: subject.dob).first
          expect(person).to be_truthy
          expect(person.broker_role).to be_falsey
          expect(person.broker_agency_staff_roles.count).to eq(1)
          expect(person.broker_agency_staff_roles[0].broker_agency_profile_id).to eq(attributes[:broker_agency_id])
        end
      end

      context 'when matched with existing person' do
        let(:other_attributes) { {
          first_name: "joe", 
          broker_applicant_type: "staff"
          }}

        before (:each) do 
          FactoryBot.create(:person, :with_ssn, first_name: 'joe', last_name: subject.last_name, dob: subject.dob)
        end

        it 'should update existing person with broker staff role' do
          expect(Person.where(first_name: 'joe', last_name: subject.last_name, dob: subject.dob)).not_to be_empty
          subject.save
          person = Person.where(first_name: "joe", last_name: subject.last_name, dob: subject.dob).first
          expect(person).to be_truthy
          expect(person.broker_role).to be_falsey
          expect(person.broker_agency_staff_roles.count).to eq(1)
          expect(person.broker_agency_staff_roles[0].broker_agency_profile_id).to eq(attributes[:broker_agency_id])
        end
      end

      context 'address' do
        let(:other_attributes) { {
          :addresses_attributes => {"0" => {
            kind: 'home',
            address_1: 'street NE',
            city: 'NewYork',
            state: 'DC',
            zip: '12345'
          }}
        }}

        before (:each) do 
          Person.delete_all
          FactoryBot.create(:person, :with_ssn, first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob)
        end

        it 'should update existing person with addresses' do
          expect(Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob)).not_to be_empty
          subject.save

          person = Person.where(first_name: subject.first_name, last_name: subject.last_name, dob: subject.dob).first

          expect(person).to be_truthy
          expect(person.addresses.last.address_1).to eq 'street NE'
          expect(person.addresses.last.city).to eq 'NewYork'
          expect(person.addresses.last.state).to eq 'DC'
          expect(person.addresses.last.zip).to eq '12345'
        end
      end
    end
  end
end
