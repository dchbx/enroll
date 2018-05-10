require 'rails_helper'

describe Forms::FamilyMember do
  let(:family_id) { double }
  let(:family) { instance_double("Family") }
  before(:each) do
    allow(Family).to receive(:find).and_return(family)
    allow(family).to receive(:family_members).and_return([])
    subject.valid?
  end

  it "should require a relationship" do
    expect(subject).to have_errors_on(:relationship)
  end


  it "should require tribal_id when citizen_status=indian_tribe_member" do
    if individual_market_is_enabled?
      subject.is_consumer_role = true
      subject.is_applying_coverage = true
      subject.indian_tribe_member = true
      subject.valid?
      expect(subject).to have_errors_on(:tribal_id)
      expect(subject.errors[:tribal_id]).to eq ["is required when native american / alaskan native is selected"]
    end
  end

  it "should not require validations on indian_tribe_member" do
    subject.is_consumer_role = true
    subject.is_applying_coverage = false
    subject.valid?
    expect(subject).not_to have_errors_on(:tribal_id)
  end

  it "should require a gender" do
    expect(subject).to have_errors_on(:gender)
  end

  it "should require a dob" do
    expect(subject).to have_errors_on(:dob)
  end

  it "should require the correct set of name components" do
    expect(subject).to have_errors_on(:first_name)
    expect(subject).to have_errors_on(:last_name)
  end

  it "should require a family_id" do
    expect(subject).to have_errors_on(:family_id)
  end

  it "should not be considered persisted" do
    expect(subject.persisted?).to be_falsey
  end

  context "initialize" do
    let(:dependent) {Forms::FamilyMember.new}
    it "should initialize address" do
      expect(dependent.addresses.class).to eq Array
      expect(dependent.addresses.count).to eq 2
      expect(dependent.addresses.first.class).to eq Address
    end

    it "should initialize same_with_primary" do
      expect(dependent.same_with_primary).to eq "true"
    end
  end

  context "compare_address_with_primary" do
    let(:addr1) {Address.new(zip: '1234', state: 'DC')}
    let(:addr2) {Address.new(zip: '4321', state: 'DC')}
    let(:addr3) {Address.new(zip: '1234', state: 'DC', 'address_3'=> "abc")}
    let(:person) {double}
    let(:primary) {double}
    let(:family) {double(primary_family_member: double(person: primary))}
    let(:family_member) {double(person: person, family: family)}

    it "without same no_dc_address" do
      allow(person).to receive(:no_dc_address).and_return true
      allow(primary).to receive(:no_dc_address).and_return false
      expect(Forms::FamilyMember.compare_address_with_primary(family_member)).to eq false
    end

    it "with same no_dc_address but without smae no_dc_address_reason" do
      allow(person).to receive(:no_dc_address).and_return true
      allow(primary).to receive(:no_dc_address).and_return true
      allow(person).to receive(:no_dc_address_reason).and_return "reason1"
      allow(primary).to receive(:no_dc_address_reason).and_return "reason2"
      expect(Forms::FamilyMember.compare_address_with_primary(family_member)).to eq false
    end

    context "with same no_dc_address and no_dc_address_reason" do
      before :each do
        allow(person).to receive(:no_dc_address).and_return true
        allow(primary).to receive(:no_dc_address).and_return true
        allow(person).to receive(:no_dc_address_reason).and_return "reason"
        allow(primary).to receive(:no_dc_address_reason).and_return "reason"
      end

      it "has same address for compare_keys" do
        allow(person).to receive(:home_address).and_return addr1
        allow(primary).to receive(:home_address).and_return addr1
        expect(Forms::FamilyMember.compare_address_with_primary(family_member)).to eq true
      end

      it "has not same address for compare_keys" do
        allow(person).to receive(:home_address).and_return addr1
        allow(primary).to receive(:home_address).and_return addr2
        expect(Forms::FamilyMember.compare_address_with_primary(family_member)).to eq false
      end

      it "has not same address but the value of compare_keys is same" do
        allow(person).to receive(:home_address).and_return addr1
        allow(primary).to receive(:home_address).and_return addr3
        expect(Forms::FamilyMember.compare_address_with_primary(family_member)).to eq true
      end
    end
  end

  context "assign_person_address" do
    let(:addr1) {Address.new(zip: '1234', state: 'DC')}
    let(:addr2) {Address.new(zip: '4321', state: 'DC')}
    let(:addr3) {Address.new(zip: '1234', state: 'DC', 'address_3' => "abc")}
    let(:person) {FactoryGirl.create(:person)}
    let(:primary) {FactoryGirl.create(:person)}
    let(:family) {double(primary_family_member: double(person: primary))}
    let(:family_member) {double(person: person, family: family)}
    let(:employee_dependent) { Forms::FamilyMember.new }

    context "if same with primary" do
      before :each do
        allow(employee_dependent).to receive(:same_with_primary).and_return 'true'
        allow(employee_dependent).to receive(:family).and_return family
      end

      it "update person's attributes" do
        allow(primary).to receive(:no_dc_address).and_return true
        allow(primary).to receive(:no_dc_address_reason).and_return "no reason"
        employee_dependent.assign_person_address(person)
        expect(person.no_dc_address).to eq true
        expect(person.no_dc_address_reason).to eq "no reason"
      end

      it "add new address if address present" do
        allow(primary).to receive(:home_address).and_return addr3
        employee_dependent.assign_person_address(person)
        expect(person.addresses.include?(addr3)).to eq true
      end

      it "not add new address if address blank" do
        allow(primary).to receive(:home_address).and_return nil
        employee_dependent.assign_person_address(person)
        expect(person.addresses.include?(addr3)).to eq false
      end
    end

    context "if not same with primary" do
      before :each do
        allow(employee_dependent).to receive(:same_with_primary).and_return 'false'
      end

      context "if address_1 is blank and city is blank" do
        let(:addresses) { {"0" => {"kind"=> 'home', "address_1" => "", "city" => ""}} }

        before :each do
          allow(person).to receive(:home_address).and_return addr3
          allow(employee_dependent).to receive(:addresses).and_return(addresses)
        end

        it "destroy current address if current_address is absent" do
          expect(addr3).to receive(:destroy).and_return true
          employee_dependent.assign_person_address(person)
        end

        it "return true" do
          allow(addr3).to receive(:destroy).and_return nil
          expect(employee_dependent.assign_person_address(person)).to eq true
        end
      end

      context "if address_1 is blank or city is not blank" do
        let(:addresses) { {"0"=>{"kind"=>"home", "address_1" => "", "city" => "not blank"}} }
        let(:address) {{"kind"=>"home", "address_1" => "", "city" => "not blank"}}

        before :each do
          allow(person).to receive(:home_address).and_return addr3
          allow(person).to receive(:has_mailing_address?).and_return false
          allow(employee_dependent).to receive(:addresses).and_return(addresses)
          allow(addresses).to receive(:values).and_return [address]
          addresses.each do |key, addr|
            addr.define_singleton_method(:permit!) {true}
          end
        end

        it "call update when current address present " do

          expect(addr3).to receive(:update).and_return true
          employee_dependent.assign_person_address(person)
        end

        it "call new when current address blank" do
          allow(person).to receive(:home_address).and_return nil

          _addresses = double(new: {})
          allow(person).to receive(:addresses).and_return _addresses

          expect(_addresses).to receive(:create).and_return true
          employee_dependent.assign_person_address(person)
        end
      end
    end
  end
end

describe Forms::FamilyMember, "which describes a new family member, and has been saved" do
  let(:family_id) { double }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:ssn) { nil }
  let(:dob) { "2007-06-09" }
  let(:existing_family_member_id) { double }
  let(:relationship) { double }
  let(:existing_family_member) { nil }
  let(:existing_person) { nil }

  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :no_ssn => '',
      :gender => "male",
      :dob => dob,
      :race => "race",
      :ethnicity => ["ethnicity"],
      :language_code => "english",
      :is_incarcerated => "no",
      :tribal_id => "test",
      :no_dc_address => nil,
      :no_dc_address_reason => nil
    }
  }

  subject { Forms::FamilyMember.new(person_properties.merge({:family_id => family_id, :relationship => relationship })) }

  before(:each) do
    allow(subject).to receive(:valid?).and_return(true)
    allow(Family).to receive(:find).with(family_id).and_return(family)
    allow(family).to receive(:find_matching_inactive_member).with(subject).and_return(existing_family_member)
    allow(Person).to receive(:match_existing_person).with(subject).and_return(existing_person)
  end

  describe "where the same family member existed previously" do
    let(:previous_family_member) { existing_family_member }
    let(:existing_family_member) { instance_double(::FamilyMember, :id => existing_family_member_id, :save! => true) }

    it "should use that family member's id" do
      allow(existing_family_member).to receive(:reactivate!).with(relationship)
      subject.save
      expect(subject.id).to eq existing_family_member.id
    end

    it "should reactivate the family member with the correct relationship." do
      expect(existing_family_member).to receive(:reactivate!).with(relationship)
      subject.save
    end
  end

  describe "that matches an existing person" do
    let(:existing_person) { instance_double("Person") }
    let(:new_family_member_id) { double }
    let(:new_family_member) { instance_double(::FamilyMember, :id => new_family_member_id, :save! => true) }

    before do
      allow(subject).to receive(:assign_person_address).and_return true
    end

    it "should create a family member for that person" do
      expect(family).to receive(:relate_new_member).with(existing_person, relationship).and_return(new_family_member)
      subject.save
      expect(subject.id).to eq new_family_member_id
    end
  end

  describe "for a new person" do
    let(:new_family_member_id) { double }
    let(:new_family_member) { instance_double(::FamilyMember, :id => new_family_member_id, :save! => true) }
    let(:new_person) { double(:save => true, :errors => double(:has_key? => false)) }

    before do
      allow(family).to receive(:relate_new_member).with(new_person, relationship).and_return(new_family_member)
      allow(family).to receive(:save!).and_return(true)
      allow(subject).to receive(:assign_person_address).and_return true
    end

    it "should create a new person" do
      person_properties[:dob] = Date.strptime(person_properties[:dob], "%Y-%m-%d")
      expect(Person).to receive(:new).with(person_properties.merge({:citizen_status=>nil})).and_return(new_person)
      subject.save
    end

    it "should create a new family member and call save_relevant_coverage_households" do
      person_properties[:dob] = Date.strptime(person_properties[:dob], "%Y-%m-%d")
      allow(Person).to receive(:new).with(person_properties.merge({:citizen_status=>nil})).and_return(new_person)
      expect(family).to receive(:save_relevant_coverage_households)
      subject.save
      expect(subject.id).to eq new_family_member_id
    end
  end
end

describe "checking validations on family member object" do
  let(:family_id) { double }
  let(:family) { double("family", :family_members => []) }
  let(:member_attributes) {
    { "first_name"=>"test",
      "middle_name"=>"",
      "last_name"=>"fm",
      "dob"=>"1982-11-11",
      "ssn"=>"",
      "no_ssn"=>"1",
      "gender"=>"male",
      "relationship"=>"child",
      "tribal_id"=>"",
      "ethnicity"=>["", "", "", "", "", "", ""],
      "is_consumer_role"=>"true",
      "same_with_primary"=>"true",
      "no_dc_address"=>"false",
      "addresses"=>
      { "0"=>{"kind"=>"home", "address_1"=>"", "address_2"=>"", "city"=>"", "state"=>"", "zip"=>""},
        "1"=>{"kind"=>"mailing", "address_1"=>"", "address_2"=>"", "city"=>"", "state"=>"", "zip"=>""}
      }
    }
  }

  subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id}))}

  before do
    allow(subject.class).to receive(:individual_market_is_enabled?).and_return(true)
    allow(subject).to receive(:family).and_return family
  end


  it "should return invalid if no answers found for required questions" do
    expect(subject.valid?).to eq false
  end

  it "should return errors with citizen status, native american / alaskan native and incarceration status" do
    subject.save
    expect(subject.errors.full_messages).to eq ["Citizenship status is required", "native american / alaskan native status is required", "Incarceration status is required"]
  end

  context "user answered for citizen status question" do
    context "when user answered us citizen as true" do
      subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id, "us_citizen"=>"true"})) }
      it "should return errors with naturalization, native american / alaskan native and incarceration status" do
        subject.save
        expect(subject.errors.full_messages).to eq ["Naturalized citizen is required", "native american / alaskan native status is required", "Incarceration status is required"]
      end
    end

    context "when user answered us citizen as false" do
      subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id, "us_citizen"=>"false"})) }
      it "should return errors with Eligible immigration, native american / alaskan native and incarceration status" do
        subject.save
        expect(subject.errors.full_messages).to eq ["Eligible immigration status is required", "native american / alaskan native status is required", "Incarceration status is required"]
      end
    end
  end

  context "when user answered for citizen & naturalization" do
    subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id, "us_citizen"=>"true", "naturalized_citizen"=>"false"})) }
    it "should return errors with native american / alaskan native and incarceration status" do
      subject.save
      expect(subject.errors.full_messages).to eq ["native american / alaskan native status is required", "Incarceration status is required"]
    end
  end

  context "when user not answered for incarceration status" do
    subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id, "us_citizen"=>"true", "naturalized_citizen"=>"false", "indian_tribe_member"=>"false"})) }
    it "should return errors with incarceration status" do
      subject.save
      expect(subject.errors.full_messages).to eq ["Incarceration status is required"]
    end
  end

  context "when satisfied with all the validations" do
    subject { Forms::FamilyMember.new(member_attributes.merge({:family_id => family_id, "us_citizen"=>"true", "naturalized_citizen"=>"false", "indian_tribe_member"=>"false", "is_incarcerated"=>"false"})) }
    it "should return true" do
      expect(subject.valid?).to eq true
    end
  end
end

describe Forms::FamilyMember, "which describes an existing family member" do
  let(:family_member_id) { double }
  let(:family_id) { double }
  let(:family) { instance_double("Family", :id => family_id) }
  let(:dob) { "2007-06-09" }
  let(:relationship) { "spouse" }
  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :gender => "male",
      :dob => Date.strptime(dob, "%Y-%m-%d"),
      :race => "race",
      :ethnicity => ["ethnicity"],
      :language_code => "english",
      :is_incarcerated => "no",
      tribal_id: "test"
    }
  }
  let(:person) { double(:errors => double(:has_key? => false), home_address: nil) }
  let(:family_member) { instance_double(::FamilyMember,
                                        person_properties.merge({
                                        :family => family,
                                        :family_id => family_id, :person => person, :primary_relationship => relationship, :save! => true})) }

  let(:update_attributes) { person_properties.merge(:family_id => family_id, :relationship => relationship, :dob => dob) }

  subject { Forms::FamilyMember.new({ :id => family_member_id }) }

  before(:each) do
    allow(FamilyMember).to receive(:find).with(family_member_id).and_return(family_member)
    allow(family_member).to receive(:citizen_status)
    allow(family_member).to receive(:naturalized_citizen)
    allow(family_member).to receive(:eligible_immigration_status)
    allow(family_member).to receive(:indian_tribe_member)
    allow(person).to receive(:has_mailing_address?).and_return(false)
    allow(subject).to receive(:valid?).and_return(true)
  end

  it "should be considered persisted" do
    expect(subject.persisted?).to be_truthy
  end


  describe "that is findable using the family_member_id" do
    before(:each) do
      allow(Forms::FamilyMember).to receive(:compare_address_with_primary).and_return false
      @found_form = Forms::FamilyMember.find(family_member_id)
    end

    it "should have the correct family_id" do
      expect(@found_form.family_id).to eq(family_id)
    end

    it "should have the existing family" do
      expect(@found_form.family).to eq family
    end
  end

  describe "when updated" do
    it "should update the relationship of the dependent" do
      allow(person).to receive(:update_attributes).with(person_properties.merge({:citizen_status=>nil, :no_ssn=>nil, :no_dc_address=>nil, :no_dc_address_reason=>nil})).and_return(true)
      allow(subject).to receive(:assign_person_address).and_return true
      allow(person).to receive(:consumer_role).and_return FactoryGirl.build(:consumer_role)
      expect(family_member).to receive(:update_relationship).with(relationship)
      subject.update_attributes(update_attributes)
    end

    it "should update the attributes of the person" do
      expect(person).to receive(:update_attributes).with(person_properties.merge({:citizen_status=>nil, :no_ssn=>nil, :no_dc_address=>nil, :no_dc_address_reason=>nil}))
      allow(family_member).to receive(:update_relationship).with(relationship)
      allow(person).to receive(:consumer_role).and_return FactoryGirl.build(:consumer_role)
      subject.update_attributes(update_attributes)
    end
  end

  context "it should create the coverage household member record if found a inactive family member record" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:new_family_member) { FactoryGirl.create(:family_member, family: family, :is_active => false)}
    before do
      allow(family).to receive(:find_matching_inactive_member).and_return new_family_member
      new_family_member.family.active_household.coverage_households.flat_map(&:coverage_household_members).select { |chm| chm.family_member_id == new_family_member.id }.each { |chm| chm.destroy! }
      subject.instance_variable_set(:@family, family)
      allow(family).to receive(:all_family_member_relations_defined).and_return true
      subject.save
      family.reload
    end

    it "should create a coverage household member record for the existing inactive family member" do
      chm = new_family_member.family.active_household.coverage_households.flat_map(&:coverage_household_members).select { |chm| chm.family_member_id == new_family_member.id }
      expect(chm.size).to eq 1
    end

    it "should set the inactive family_member as active" do
      expect(new_family_member.is_active).to eq true
    end
  end
end

describe Forms::FamilyMember, "relationship validation" do
  let(:family) { FactoryGirl.build(:family) }
  let(:family_member) { FactoryGirl.build(:family_member, family: family) }
  let(:family_members) { family.family_members}
  let(:ssn) { nil }
  let(:dob) { "2007-06-09" }

  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :gender => "male",
      :dob => dob
    }
  }

  before(:each) do
    allow(Family).to receive(:find).with(family.id).and_return(family)
    allow(family).to receive(:family_members).and_return(family_members)
    allow(family_members).to receive(:where).and_return([family_member])
  end

  context "spouse" do
    let(:relationship) { "spouse" }
    subject { Forms::FamilyMember.new(person_properties.merge({:family_id => family.id, :relationship => relationship })) }

    it "should fail with multiple spouse" do
      allow(family_member).to receive(:relationship).and_return("spouse")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner")
    end

    it "should fail with spouse and life_partner" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner")
    end
  end

  context "life_partner" do
    let(:relationship) { "life_partner" }
    subject { Forms::FamilyMember.new(person_properties.merge({:family_id => family.id, :relationship => relationship })) }

    it "should fail with multiple life_partner" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner")
    end
  end

  context "change to spouse from life_partner" do
    let(:relationship) { "spouse" }

    it "should success" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      allow(family_member).to receive(:reactivate!).and_return(true)
      allow(family_member).to receive(:is_primary_applicant?).and_return(true)
      allow(family_member).to receive(:is_active?).and_return(true)
      allow(FamilyMember).to receive(:find).and_return(family_member)

      dependent = Forms::FamilyMember.find(family_member.id)
      dependent.update_attributes(person_properties.merge({:family_id => family.id, :relationship => relationship, :id => family_member.id }))

      expect(dependent.valid?).to be true
      expect(dependent.errors[:base].any?).to be_falsey
    end
  end
end
