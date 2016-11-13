require 'rails_helper'

describe Person do

  describe "model" do
    it { should validate_presence_of :first_name }
    it { should validate_presence_of :last_name }

    let(:first_name) {"Martina"}
    let(:last_name) {"Williams"}
    let(:ssn) {"657637863"}
    let(:gender) {"male"}
    let(:address) {FactoryGirl.build(:address)}
    let(:valid_params) do
      { first_name: first_name,
        last_name: last_name,
        ssn: ssn,
        gender: gender,
        addresses: [address]
      }
    end

    describe ".create", dbclean: :after_each do
      context "with valid arguments" do
        let(:params) {valid_params}
        let(:person) {Person.create(**params)}
        before do
          person.valid?
        end

        it 'should generate hbx_id' do
          expect(person.hbx_id).to be_truthy
        end

        context "and a second person is created with the same ssn" do
          let(:person2) {Person.create(**params)}
          before do
            person2.valid?
          end

          context "the second person" do
            it "should not be valid" do
              expect(person2.valid?).to be false
            end

            it "should have an error on ssn" do
              expect(person2.errors[:ssn].any?).to be true
            end

            it "should not have the same id as the first person" do
              expect(person2.id).not_to eq person.id
            end
          end
        end
      end
    end

    describe ".new" do
      context "with no arguments" do
        let(:params) {{}}

        it "should be invalid" do
          expect(Person.new(**params).valid?).to be_falsey
        end
      end

      context "with all valid arguments" do
        let(:params) {valid_params}
        let(:person) {Person.new(**params)}

        it "should save" do
          expect(person.valid?).to be_truthy
        end

        it "should known its relationship is self" do
          expect(person.find_relationship_with(person)).to eq "self"
        end

        it "unread message count is accurate" do
          expect(person.inbox).to be nil
          person.save
          expect(person.inbox.messages.count).to eq 1
          expect(person.inbox.unread_messages.count).to eq 1
        end


      end

      context "with no first_name" do
        let(:params) {valid_params.except(:first_name)}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:first_name].any?).to be_truthy
        end
      end

      context "with no last_name" do
        let(:params) {valid_params.except(:last_name)}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:last_name].any?).to be_truthy
        end
      end

      context "with no ssn" do
        let(:params) {valid_params.except(:ssn)}

        it "should not fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end
      end

      context "with invalid gender" do
        let(:params) {valid_params.deep_merge({gender: "abc"})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:gender]).to eq ["abc is not a valid gender"]
        end
      end

      context 'duplicated key issue' do
        before do
          Person.remove_indexes
          Person.create_indexes
        end
        context "with blank ssn" do

          let(:params) {valid_params.deep_merge({ssn: ""})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:ssn].any?).to be_falsey
          end

          it "allow duplicated blank ssn" do
            person1 = Person.create(**params)
            person2 = Person.create(**params)
            expect(person2.errors[:ssn].any?).to be_falsey
          end
        end

        context "with nil ssn" do
          let(:params) {valid_params.deep_merge({ssn: nil})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:ssn].any?).to be_falsey
          end

          it "allow duplicated blank ssn" do
            person1 = Person.create(**params)
            person2 = Person.create(**params)
            expect(person2.errors[:ssn].any?).to be_falsey
          end
        end
      end

      context "with nil ssn" do
        let(:params) {valid_params.deep_merge({ssn: ""})}

        it "should not fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end
      end

      context "with invalid ssn" do
        let(:params) {valid_params.deep_merge({ssn: "123345"})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn]).to eq ["SSN must be 9 digits"]
        end
      end

      context "with date of birth" do
        let(:dob){ 25.years.ago }
        let(:params) {valid_params.deep_merge({dob: dob})}

        before(:each) do
          @person = Person.new(**params)
        end

        it "should get the date of birth" do
          expect(@person.date_of_birth).to eq dob.strftime("%m/%d/%Y")
        end

        it "should set the date of birth" do
          @person.date_of_birth = "01/01/1985"
          expect(@person.dob.to_s).to eq "01/01/1985"
        end

        it "should return date of birth as string" do
          expect(@person.dob_to_string).to eq dob.strftime("%Y%m%d")
        end

        it "should return if a person is active or not" do
          expect(@person.is_active?).to eq true
          @person.is_active = false
          expect(@person.is_active?).to eq false
        end

=begin
        context "dob more than 110 years ago" do
          let(:dob){ 200.years.ago }

          it "should have a validation error" do
            expect(@person.valid?).to be_falsey
            expect(@person.errors.full_messages).to include("Dob date cannot be more than 110 years ago")
          end

        end
=end
      end

      context "with invalid date values" do
        context "and date of birth is in future" do
          let(:params) {valid_params.deep_merge({dob: TimeKeeper.date_of_record + 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:dob].size).to eq 1
          end
        end

        context "and date of death is in future" do
          let(:params) {valid_params.deep_merge({date_of_death: TimeKeeper.date_of_record + 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:date_of_death].size).to eq 1
          end
        end

        context "and date of death preceeds date of birth" do
          let(:params) {valid_params.deep_merge({date_of_death: Date.today - 10, dob: Date.today - 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:date_of_death].size).to eq 1
          end
        end
      end
      
      context "has_employer_benefits?" do
        let(:person) {FactoryGirl.build(:person)}
        let(:benefit_group) { FactoryGirl.build(:benefit_group)}
        let(:employee_roles) {double(active: true)}
        let(:census_employee) { double }

        before do
          allow(employee_roles).to receive(:census_employee).and_return(census_employee)
          allow(census_employee).to receive(:is_active?).and_return(true)
          allow(employee_roles).to receive(:benefit_group).and_return(benefit_group)
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          allow(employee_roles).to receive(:benefit_group).and_return(benefit_group)
          expect(person.has_employer_benefits?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:employee_roles).and_return([])
          expect(person.has_employer_benefits?).to eq false
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          allow(employee_roles).to receive(:benefit_group).and_return(nil)
          expect(person.has_employer_benefits?).to eq false
        end

      end
      
      context "has_active_employee_role?" do
        let(:person) {FactoryGirl.build(:person)}
        let(:employee_roles) {double(active: true)}
        let(:census_employee) { double }

        before do
          allow(employee_roles).to receive(:census_employee).and_return(census_employee)
          allow(census_employee).to receive(:is_active?).and_return(true)
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          expect(person.has_active_employee_role?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:employee_roles).and_return([])
          expect(person.has_active_employee_role?).to eq false
        end
      end

      context "with invalid Tribal Id" do
        let(:params) {valid_params.deep_merge({tribal_id: "12124"})}

        it "should fail validation" do
          person = Person.new(**params)
          person.us_citizen = "true"
          person.indian_tribe_member = "1"
          allow(person).to receive(:is_consumer_role).and_return(:true)
          expect(person.valid?).to eq false
          expect(person.errors[:base]).to eq ["Tribal id must be 9 digits"]
        end
      end


      context "has_active_consumer_role?" do
        let(:person) {FactoryGirl.build(:person)}
        let(:consumer_role) {double(is_active?: true)}

        it "should return true" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          expect(person.has_active_consumer_role?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:consumer_role).and_return(nil)
          expect(person.has_active_consumer_role?).to eq false
        end
      end

      context "has_multiple_roles?" do
        let(:person) {FactoryGirl.build(:person)}
        let(:employee_roles) {double(active: true)}
        let(:consumer_role) {double(is_active?: true)}

        it "returns true if person has consumer_role and employee_roles" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)

          expect(person.has_multiple_roles?).to eq true
        end

        it "returns false if person has only consumer_role" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:active_employee_roles).and_return(nil)

          expect(person.has_multiple_roles?).to eq false
        end

        it "returns false if person has only consumer_role" do
          allow(person).to receive(:consumer_role).and_return(nil)
          allow(person).to receive(:employee_roles).and_return(employee_roles)

          expect(person.has_multiple_roles?).to eq false
        end

        it "returns false if person has no roles" do
          allow(person).to receive(:consumer_role).and_return(nil)
          allow(person).to receive(:employee_roles).and_return(nil)

          expect(person.has_multiple_roles?).to eq false
        end
      end
    end
  end

  describe '.match_by_id_info' do
    before(:all) do
      @p0 = Person.create!(first_name: "Jack",   last_name: "Bruce",   dob: "1943-05-14", ssn: "517994321")
      @p1 = Person.create!(first_name: "Ginger", last_name: "Baker",   dob: "1939-08-19", ssn: "888007654")
      @p2 = Person.create!(first_name: "Eric",   last_name: "Clapton", dob: "1945-03-30", ssn: "666332345")
      @p4 = Person.create!(first_name: "Joe",   last_name: "Kramer", dob: "1993-03-30")
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it 'matches by last_name, first name and dob if no previous ssn and no current ssn' do
      expect(Person.match_by_id_info(last_name: @p4.last_name, dob: @p4.dob, first_name: @p4.first_name)).to eq [@p4]
    end

    it 'matches by last_name, first name and dob if no previous ssn and yes current ssn' do
      expect(Person.match_by_id_info(last_name: @p4.last_name, dob: @p4.dob, first_name: @p4.first_name, ssn: '123123123')).to eq [@p4]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p0.dob, first_name: @p0.first_name)).to eq [@p0]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn and UPPERCASED' do
      expect(Person.match_by_id_info(last_name: @p0.last_name.upcase, dob: @p0.dob, first_name: @p0.first_name.upcase)).to eq [@p0]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn and LOWERCASED' do
      expect(Person.match_by_id_info(last_name: @p0.last_name.downcase, dob: @p0.dob, first_name: @p0.first_name.downcase)).to eq [@p0]
    end

    it 'matches by ssn' do
      expect(Person.match_by_id_info(ssn: @p1.ssn)).to eq [@p1]
    end

    it 'matches by ssn, last_name and dob' do
      expect(Person.match_by_id_info(last_name: @p2.last_name, dob: @p2.dob, ssn: @p2.ssn)).to eq [@p2]
    end

    it 'not match last_name and dob if not on same record' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p1.dob, first_name: @p4.first_name).size).to eq 0
    end

    it 'returns empty array for non-matches' do
      expect(Person.match_by_id_info(ssn: "577600345")).to eq []
    end

    it 'not match last_name and dob if ssn provided (match is already done if ssn ok)' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p0.dob, ssn: '999884321').size).to eq 0
    end
  end

  describe '.active', :dbclean => :after_each do
    it 'new person defaults to is_active' do
      expect(Person.create!(first_name: "eric", last_name: "Clapton").is_active).to eq true
    end

    it 'returns person records only where is_active == true' do
      p1 = Person.create!(first_name: "Jack", last_name: "Bruce", is_active: false)
      p2 = Person.create!(first_name: "Ginger", last_name: "Baker")
      expect(Person.active.size).to eq 1
      expect(Person.active.first).to eq p2
    end
  end

  ## Instance methods
  describe '#addresses' do
    it "invalid address bubbles up" do
      person = Person.new
      addresses = person.addresses.build({address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})
      expect(person.valid?).to eq false
      expect(person.errors[:addresses].any?).to eq true
    end

    it 'persists associated address', dbclean: :after_each do
      # setup
      person = FactoryGirl.build(:person)
      addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

      result = person.save

      expect(result).to eq true
      expect(person.addresses.first.kind).to eq "home"
      expect(person.addresses.first.city).to eq "Washington"
    end
  end

  describe '#find_all_staff_roles_by_employer_profile' do
    employer_profile = FactoryGirl.build(:employer_profile)
    person = FactoryGirl.build(:person)
    FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)
    it "should have the same search criteria" do
      allow(Person).to receive(:where).and_return([person])
      expect(Person.find_all_staff_roles_by_employer_profile(employer_profile)).to eq [person]
    end

  end

  describe "large family with multiple employees - The Brady Bunch", :dbclean => :after_all do
    include_context "BradyBunchAfterAll"

    before :all do
      create_brady_families
    end

    context "a person" do
      it "should know its age today" do
        expect(greg.age_on(Date.today)).to eq gregs_age
      end

      it "should know its age on a given date" do
        expect(greg.age_on(18.months.ago.to_date)).to eq (gregs_age - 2)
      end

      it "should know its age yesterday" do
        expect(greg.age_on(Date.today.advance(days: -1))).to eq (gregs_age - 1)
      end

      it "should know its age tomorrow" do
        expect(greg.age_on(1.day.from_now.to_date)).to eq gregs_age
      end
    end

    context "Person#primary_family" do
      context "on Mike" do
        let(:find) {mike.primary_family}
        it "should find Mike's family" do
          expect(find.id.to_s).to eq mikes_family.id.to_s
        end
      end

      context "on Carol" do
        let(:find) {carol.primary_family}
        it "should find Carol's family" do
          expect(find.id.to_s).to eq carols_family.id.to_s
        end
      end
    end

    context "Person#families" do
      context "on Mike" do
        let(:find) {mike.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end

      context "on Carol" do
        let(:find) {carol.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end

      context "on Greg" do
        let(:find) {greg.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end
    end
  end

  describe '#person_relationships' do
    it 'accepts associated addresses' do
      # setup
      person = FactoryGirl.build(:person)
      relationship = person.person_relationships.build({kind: "self", relative: person})

      expect(person.save).to eq true
      expect(person.person_relationships.size).to eq 1
      expect(relationship.invert_relationship.kind).to eq "self"
    end
  end

  describe '#full_name' do
    it 'returns the concatenated name attributes' do
      expect(Person.new(first_name: "Ginger", last_name: "Baker").full_name).to eq 'Ginger Baker'
    end
  end

  describe '#phones' do
    it "sets person's home telephone number" do
      person = Person.new
      person.phones.build({kind: 'home', area_code: '202', number: '555-1212'})

      # expect(person.phones.first.number).to eq '5551212'
    end
  end

  describe '#emails' do
    it "sets person's home email" do
      person = Person.new
      person.emails.build({kind: 'home', address: 'sam@example.com'})
      expect(person.emails.first.address).to eq 'sam@example.com'
    end
  end
  
  describe '#work_email_or_best' do
    it "expects to get a work email address or home address" do
      person = Person.new
      person.emails.build({kind: 'work', address: 'work1@example.com'})
      expect(person.work_email_or_best).to eq 'work1@example.com'
    end
  end

  describe '#families' do
    it 'returns families where the person is present' do
    end
  end

  describe "with no relationship to a dependent" do
    describe "after ensure_relationship_with" do
      it "should have the new relationship"
    end
  end

  describe "with an existing relationship to a dependent" do
    describe "after ensure_relationship_with a different type of relationship" do
      it "should correct the existing relationship"
    end
  end

  describe "call notify change event when after save" do
    before do
      extend Notify
    end

    context "notify change event" do
      let(:person){FactoryGirl.build(:person)}
      it "when new record" do
        #      expect(person).to receive(:notify_change_event).exactly(1).times
        person.save
      end

      it "when change record" do
        #      expect(person).to receive(:notify_change_event).exactly(1).times
        first_name = person.first_name
        person.first_name = "Test"
        person.save
      end
    end
  end

  describe "need_to_notify?" do
    let(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:person2) { FactoryGirl.create(:person, :with_employee_role) }
    let(:person3) { FactoryGirl.create(:person, :with_employer_staff_role) }

    it "should return true when update consumer_role" do
      consumer_role = person1.consumer_role
      consumer_role.birth_location = 'DC'
      person1.updated_at = TimeKeeper.datetime_of_record
      expect(person1.need_to_notify?).to be_truthy
    end

    it "should return false when update consumer_role's bookmark_url" do
      consumer_role = person1.consumer_role
      consumer_role.bookmark_url = '/families/home'
      expect(person1.need_to_notify?).to be_falsey
    end

    it "should return true when update employee_roles" do
      employee_role = person2.employee_roles.first
      employee_role.language_preference = "Spanish"
      expect(person2.need_to_notify?).to be_truthy
    end

    it "should return false when update employee_role's bookmark_url" do
      employee_role = person2.employee_roles.first
      employee_role.bookmark_url = "/families/home"
      expect(person2.need_to_notify?).to be_falsey
    end

    it "should return true when update employer_staff_role" do
      employer_staff_role = person3.employer_staff_roles.first
      employer_staff_role.is_owner = false
      expect(person3.need_to_notify?).to be_truthy
    end

    it "should return false when update employer_staff_role's bookmark_url" do
      employer_staff_role = person3.employer_staff_roles.first
      employer_staff_role.bookmark_url = "/families"
      expect(person3.need_to_notify?).to be_falsey
    end

    context "call notify" do
      it "when change person record" do
        expect(person1).to receive(:notify).exactly(1).times
        person1.first_name = "Test"
        person1.save
      end

      it "when change consumer_role record" do
        expect(person1).to receive(:notify).exactly(1).times
        person1.consumer_role.update_attribute(:birth_location, 'DC')
      end

      it "when change employee_role record" do
        expect(person2).to receive(:notify).exactly(1).times
        person2.employee_roles.last.update_attribute(:language_preference, 'Spanish')
      end

      #it "when change employer_staff_role record" do
      #  expect(person3).to receive(:notify).exactly(1).times
      #  person3.employer_staff_roles.first.update_attribute(:aasm_state, 'is_closed')
      #end
    end

    context "should not call notify" do
      it "when change consumer_role's bookmark_url" do
        expect(person1).to receive(:notify).exactly(0).times
        person1.consumer_role.update_attribute(:bookmark_url, '/families/home')
      end

      it "when change employee_role's bookmark_url" do
        expect(person2).to receive(:notify).exactly(0).times
        person2.employee_roles.last.update_attribute(:bookmark_url, '/families/home')
      end

      it "when change employer_staff_role's bookmark_url" do
        expect(person3).to receive(:notify).exactly(0).times
        person3.employer_staff_roles.last.update_attribute(:bookmark_url, '/families/home')
      end
    end
  end


  describe "does not allow two people with the same user ID to be saved" do
    let(:person1){FactoryGirl.build(:person)}
    let(:person2){FactoryGirl.build(:person)}

    it "should let fail to save" do
      user_id = BSON::ObjectId.new
      person1.user_id = user_id
      person2.user_id = user_id
      person1.save!
      expect { person2.save! }.to raise_error(Mongo::Error::OperationFailure)
    end

  end

  describe "persisted with no user" do
    let(:person1){FactoryGirl.create(:person)}
    let(:user1){FactoryGirl.create(:user)}

    it "should be fine with having a user assigned" do
      person1.user = user1
      expect(person1.valid?).to eq(true)
    end
  end

  describe "persisted with a user" do
    let(:person1){FactoryGirl.create(:person)}
    let(:user1){FactoryGirl.create(:user)}
    let(:user2){FactoryGirl.create(:user)}

    before :each do
      person1.user = user1
      person1.save!
    end

    it "should not allow a different user to be assigned" do
      expect(person1.valid?).to eq(true)
      person1.user = user2
      expect(person1.valid?).to eq(false)
    end
    it "should allow the same user to be assigned" do
      expect(person1.valid?).to eq(true)
      person1.user = nil
      person1.user = user1
      expect(person1.valid?).to eq(true)
    end
  end

  describe "validation of date_of_birth and date_of_death" do
    let(:person) { FactoryGirl.create(:person) }

    context "validate of date_of_birth_is_past" do
      it "should invalid" do
        dob = (Date.today + 10.days)
        allow(person).to receive(:dob).and_return(dob)
        expect(person.save).to be_falsey
        expect(person.errors[:dob].any?).to be_truthy
        expect(person.errors[:dob].to_s).to match /future date: #{dob.to_s} is invalid date of birth/
      end
    end

    context "date_of_death_is_blank_or_past" do
      it "should invalid" do
        date_of_death = (Date.today + 10.days)
        allow(person).to receive(:date_of_death).and_return(date_of_death)
        expect(person.save).to be_falsey
        expect(person.errors[:date_of_death].any?).to be_truthy
        expect(person.errors[:date_of_death].to_s).to match /future date: #{date_of_death.to_s} is invalid date of death/
      end
    end
  end

  describe "us_citizen status" do
    let(:person) { FactoryGirl.create(:person) }

    before do
      person.us_citizen="false"
    end

    context "set to false" do
      it "should set @us_citizen to false" do
        expect(person.us_citizen).to be_falsey
      end

      it "should set @naturalized_citizen to false" do
        expect(person.naturalized_citizen).to be_falsey
      end
    end
  end

  describe "residency_eligible?" do
    let(:person) { FactoryGirl.create(:person) }

    it "should false" do
      person.no_dc_address = false
      person.no_dc_address_reason = ""
      expect(person.residency_eligible?).to be_falsey
    end

    it "should false" do
      person.no_dc_address = true
      person.no_dc_address_reason = ""
      expect(person.residency_eligible?).to be_falsey
    end

    it "should true" do
      person.no_dc_address = true
      person.no_dc_address_reason = "I am Homeless"
      expect(person.residency_eligible?).to be_truthy
    end
  end

  describe "home_address" do
    let(:person) { FactoryGirl.create(:person) }

    it "return home address" do
      address_1 = Address.new(kind: 'home')
      address_2 = Address.new(kind: 'mailing')
      allow(person).to receive(:addresses).and_return [address_1, address_2]

      expect(person.home_address).to eq address_1
    end
  end

  describe "is_dc_resident?" do
    context "when no_dc_address is true" do
      let(:person) { Person.new(no_dc_address: true) }

      it "return false with no_dc_address_reason" do
        allow(person).to receive(:no_dc_address_reason).and_return "reason"
        expect(person.is_dc_resident?).to eq true
      end

      it "return true without no_dc_address_reason" do
        allow(person).to receive(:no_dc_address_reason).and_return ""
        expect(person.is_dc_resident?).to eq false
      end
    end

    context "when no_dc_address is false" do
      let(:person) { Person.new(no_dc_address: false) }

      context "when state is not dc" do
        let(:home_addr) {Address.new(kind: 'home', state: 'AC')}
        let(:mailing_addr) {Address.new(kind: 'mailing', state: 'AC')}
        let(:work_addr) { Address.new(kind: 'work', state: 'AC') }
        it "home" do
          allow(person).to receive(:addresses).and_return [home_addr]
          expect(person.is_dc_resident?).to eq false
        end

        it "mailing" do
          allow(person).to receive(:addresses).and_return [mailing_addr]
          expect(person.is_dc_resident?).to eq false
        end

        it "work" do
          allow(person).to receive(:addresses).and_return [work_addr]
          expect(person.is_dc_resident?).to eq false
        end
      end

      context "when state is dc" do
        let(:home_addr) {Address.new(kind: 'home', state: 'DC')}
        let(:mailing_addr) {Address.new(kind: 'mailing', state: 'DC')}
        let(:work_addr) { Address.new(kind: 'work', state: 'DC') }
        it "home" do
          allow(person).to receive(:addresses).and_return [home_addr]
          expect(person.is_dc_resident?).to eq true
        end

        it "mailing" do
          allow(person).to receive(:addresses).and_return [mailing_addr]
          expect(person.is_dc_resident?).to eq true
        end

        it "work" do
          allow(person).to receive(:addresses).and_return [work_addr]
          expect(person.is_dc_resident?).to eq false
        end
      end
    end
  end

  describe "assisted and unassisted" do
    context "is_aqhp?" do
      let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
      let(:person1) {FactoryGirl.create(:person, :with_consumer_role)}
      let(:person2) {FactoryGirl.create(:person, :with_consumer_role)}
      let(:family1)  {FactoryGirl.create(:family, :with_primary_family_member)}
      let(:household) {FactoryGirl.create(:household, family: family1)}
      let(:tax_household) {FactoryGirl.create(:tax_household, household: household) }
      let(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}

      before :each do
        family1.households.first.tax_households<<tax_household
        family1.save
        @person_aqhp = family1.primary_applicant.person
      end
      it "creates person with status verification_pending" do
        expect(person.consumer_role.aasm_state).to eq("unverified")
      end

      it "returns people with uverified status" do
        expect(Person.unverified_persons.include? person1).to eq(true)
      end

      it "doesn't return people with verified status" do
        person2.consumer_role.aasm_state = "fully_verified"
        person2.save
        expect(Person.unverified_persons.include? person2).to eq(false)
      end

      it "creates family with households and tax_households" do
        expect(family1.households.first.tax_households).not_to be_empty
      end

      it "true if person family households present" do
        expect(@person_aqhp.check_households(family1)).to eq true
      end

      it "true if person family households tax_households present" do
        expect(@person_aqhp.check_tax_households(family1)).to eq true
      end

      it "returns true if persons is AQHP" do
        expect(@person_aqhp.is_aqhp?).to eq true
      end
    end
  end

  describe "verification types" do
    let(:person) {FactoryGirl.create(:person)}

    shared_examples_for "collecting verification types for person" do |v_types, types_count, ssn, citizen, native|
      before do
        allow(person).to receive(:ssn).and_return(ssn) if ssn
        allow(person).to receive(:us_citizen).and_return(citizen)
        allow(person).to receive(:citizen_status).and_return("indian_tribe_member") if native
      end
      it "returns array of verification types" do
        expect(person.verification_types).to be_a Array
      end

      it "returns #{types_count} verification types" do
        expect(person.verification_types.count).to eq types_count
      end

      it "contains #{v_types} verification types" do
        expect(person.verification_types).to eq v_types
      end
    end

    context "SSN + Citizen" do
      it_behaves_like "collecting verification types for person", ["Social Security Number", "Citizenship"], 2, "2222222222", true
    end

    context "SSN + Immigrant" do
      it_behaves_like "collecting verification types for person", ["Social Security Number", "Immigration status"], 2, "2222222222", false
    end

    context "SSN + Native Citizen" do
      it_behaves_like "collecting verification types for person", ["Social Security Number", "American Indian Status", "Citizenship"], 3, "2222222222", true, "native"
    end

    context "Citizen with NO SSN" do
      it_behaves_like "collecting verification types for person", ["Citizenship"], 1, nil, true
    end

    context "Immigrant with NO SSN" do
      it_behaves_like "collecting verification types for person", ["Immigration status"], 1, nil, false
    end

    context "Native Citizen with NO SSN" do
      it_behaves_like "collecting verification types for person", ["American Indian Status", "Citizenship"], 2, nil, true, "native"
    end

  end

  describe ".add_employer_staff_role(first_name, last_name, dob, email, employer_profile)" do
    let(:employer_profile){FactoryGirl.create(:employer_profile)}
    let(:person_params) {{first_name: Forgery('name').first_name, last_name: Forgery('name').first_name, dob: '1990/05/01'}}
    let(:person1) {FactoryGirl.create(:person, person_params)}

    context 'duplicate person PII' do
      before do
        FactoryGirl.create(:person, person_params)
        @status, @result = Person.add_employer_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', employer_profile )
      end
      it 'returns false' do
        expect(@status).to eq false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end

    context 'zero matching person PII' do
      before {@status, @result = Person.add_employer_staff_role('sam', person1.last_name, person1.dob,'#default@email.com', employer_profile )}

      it 'returns false' do
        expect(@status).to eq false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end

    context 'matching one person PII' do
      before {@status, @result = Person.add_employer_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', employer_profile )}

      it 'returns true' do
        expect(@status).to eq true
      end

      it 'returns the person' do
        expect(@result).to eq person1
      end
    end
  end

  describe ".deactivate_employer_staff_role" do
    let(:person) {FactoryGirl.create(:person)}
    let(:employer_staff_role) {FactoryGirl.create(:employer_staff_role, person: person)}
    let(:employer_staff_roles) { FactoryGirl.create_list(:employer_staff_role, 3, person: person) } 
    context 'does not find the person' do
      before {@status, @result = Person.deactivate_employer_staff_role(1, employer_staff_role.employer_profile_id)}
      it 'returns false' do
        expect(@status).to be false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end
    context 'finds the person and inactivates the role' do
      before {@status, @result = Person.deactivate_employer_staff_role(person.id, employer_staff_role.employer_profile_id)}
      it 'returns true' do
        expect(@status).to be true
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end

      it 'sets is_active to false' do
        expect(employer_staff_role.reload.is_active?).to eq false
      end
    end

    context 'finds the person and inactivates all roles' do
      before {@status, @result = Person.deactivate_employer_staff_role(person.id, employer_staff_role.employer_profile_id)}
      it 'returns true' do
        expect(@status).to be true
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end

      it 'has more than one employer_staff_role' do
        employer_staff_roles 
        expect(person.employer_staff_roles.count).to eq (employer_staff_roles << employer_staff_role).count
      end

      it 'sets is_active to false for each role' do
        expect(person.employer_staff_roles.each { |role| role.reload.is_active? == false })
      end
    end
  end

  describe "person_has_an_active_enrollment?" do


    let(:person) { FactoryGirl.create(:person) }
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person) }
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }


    context 'person_has_an_active_enrollment?' do
      let(:active_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                           household: primary_family.latest_household,
                                          employee_role_id: employee_role.id,
                                          is_active: true
                                       )}

      it 'returns true if person has an active enrollment.' do

        allow(person).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([active_enrollment])
        expect(Person.person_has_an_active_enrollment?(person)).to be_truthy
      end
    end

    context 'person_has_an_inactive_enrollment?' do
      let(:inactive_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                           household: primary_family.latest_household,
                                          employee_role_id: employee_role.id,
                                          is_active: false
                                       )}

      it 'returns false if person does not have any active enrollment.' do

        allow(person).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([inactive_enrollment])
        expect(Person.person_has_an_active_enrollment?(person)).to be_falsey
      end
    end

  end

  describe "has_active_employee_role_for_census_employee?" do
    let(:person) { FactoryGirl.create(:person) }
    let(:census_employee) { FactoryGirl.create(:census_employee) }
    let(:census_employee2) { FactoryGirl.create(:census_employee) }

    context "person has no active employee roles" do
      it "should return false" do
        expect(person.active_employee_roles).to be_empty
        expect(person.has_active_employee_role_for_census_employee?(census_employee)).to be_falsey
      end
    end

    context "person has active employee roles" do
      before(:each) do
        person.employee_roles.create!(FactoryGirl.create(:employee_role, person: person, 
                                                                       census_employee_id: census_employee.id).attributes)
        person.employee_roles.pluck(:census_employee).each { |census_employee| census_employee.update_attribute(:aasm_state, 'eligible') }
      end

      it "should return true if person has active employee role for given census_employee" do
        expect(person.active_employee_roles).to be_present
        expect(person.has_active_employee_role_for_census_employee?(census_employee)).to be_truthy
      end

      it "should return false if person does not have active employee role for given census_employee" do
        expect(person.active_employee_roles).to be_present
        expect(person.has_active_employee_role_for_census_employee?(census_employee2)).to be_falsey
      end
    end
   end

  describe "agent?" do
    let(:person) { FactoryGirl.create(:person) }

    it "should return true with general_agency_staff_roles" do
      person.general_agency_staff_roles << FactoryGirl.build(:general_agency_staff_role)
      expect(person.agent?).to be_truthy
    end
  end
  
  describe "dob_change_implication_on_active_enrollments" do
    
    let(:persons_dob) { TimeKeeper.date_of_record - 19.years }
    let(:person) { FactoryGirl.create(:person, dob: persons_dob) }
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              aasm_state: 'coverage_selected',
                                              effective_on: TimeKeeper.date_of_record - 10.days,
                                              is_active: true
                                            )}
    let(:new_dob_with_premium_implication)    { TimeKeeper.date_of_record - 35.years }
    let(:new_dob_without_premium_implication) { TimeKeeper.date_of_record - 17.years }
    
    let(:premium_implication_hash) { {enrollment.id => true} }
    let(:empty_hash) { {} } 

    before do
      allow(person).to receive(:primary_family).and_return(primary_family)
      allow(primary_family).to receive(:enrollments).and_return([enrollment])
    end

    it "should return a NON-EMPTY hash with at least one enrollment if DOB change RESULTS in premium change" do
      expect(Person.dob_change_implication_on_active_enrollments(person, new_dob_with_premium_implication)).to eq premium_implication_hash
    end

    it "should return an EMPTY hash if DOB change DOES NOT RESULT in premium change" do
      expect(Person.dob_change_implication_on_active_enrollments(person, new_dob_without_premium_implication)).to eq empty_hash
    end
    
    context 'edge case when DOB change makes person 61' do
      
      let(:age_older_than_sixty_one) { TimeKeeper.date_of_record - 75.years }
      let(:person_older_than_sixty_one) { FactoryGirl.create(:person, dob: age_older_than_sixty_one) }
      let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
      let(:new_dob_with_premium_implication)    { TimeKeeper.date_of_record - 35.years }
      let(:enrollment)   { FactoryGirl.create( :hbx_enrollment, household: primary_family.latest_household, aasm_state: 'coverage_selected', effective_on: Date.new(2016,1,1), is_active: true)}
      let(:new_dob_to_make_person_sixty_one)    { Date.new(1955,1,1) }
  
      before do
        allow(person_older_than_sixty_one).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([enrollment])
      end

      it "should return an EMPTY hash if a person more than 61 year old changes their DOB so that they are 61 on the day the coverage starts" do
        expect(Person.dob_change_implication_on_active_enrollments(person_older_than_sixty_one, new_dob_to_make_person_sixty_one)).to eq empty_hash 
      end

    end
  end 

  describe "given a consumer role" do
    let(:consumer_role) { ConsumerRole.new }
    let(:subject) { Person.new(:consumer_role => consumer_role) }

    it "delegates #ivl_coverage_selected to consumer role" do
      expect(consumer_role).to receive(:ivl_coverage_selected)
      subject.ivl_coverage_selected
    end
  end

  describe "without a consumer role" do
    let(:subject) { Person.new }

    it "delegates #ivl_coverage_selected to nowhere" do
      expect { subject.ivl_coverage_selected }.not_to raise_error
    end
  end

  describe "changing the bookmark url for a consumer role" do
    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_family) }
    let(:household) { FactoryGirl.create(:household, family: person.primary_family) }
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: person.primary_family.latest_household, kind: "individual")}
    before(:each) do
      allow(household).to receive(:hbx_enrollments).with(:first).and_return enrollment
    end

    it "should not change the bookmark_url if they not passed RIDP" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attributes(:idp_verified => false)
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      person.set_consumer_role_url
      expect(person.consumer_role.bookmark_url).to eq "/insured/family_members?consumer_role_id"
    end

    it "should not change the bookmark_url if they don't have addresses" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attributes(:idp_verified => true)
      person.user.ridp_by_payload!
      person.addresses.to_a.each do |add|
        add.delete
      end
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      person.set_consumer_role_url
      expect(person.consumer_role.bookmark_url).to eq "/insured/family_members?consumer_role_id"
    end

    it "should change the bookmark_url if it has addresses, active enrollment and passed RIDP" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attribute(:idp_verified, true)
      person.user.ridp_by_payload!
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      person.set_consumer_role_url
      expect(person.consumer_role.bookmark_url).to eq "/families/home"
    end
  end
end
