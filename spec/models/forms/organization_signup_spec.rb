require "rails_helper"

describe Forms::OrganizationSignup, "office location kind validtion", :dbclean => :after_each do
  context "give more than one office location of the primary type" do
    let(:office_location_1) { OfficeLocation.new( :address => Address.new(:kind => "primary") ) }
    let(:office_location_2) { OfficeLocation.new( :address => Address.new(:kind => "primary") ) }
    subject { Forms::OrganizationSignup.new( :office_locations => [office_location_1, office_location_2]) }

    it "should be invalid" do
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can't have multiple primary addresses")
    end
  end

  context "give more than one office location of the mailing type" do
    let(:office_location_1) { OfficeLocation.new( :address => Address.new(:kind => "mailing") ) }
    let(:office_location_2) { OfficeLocation.new( :address => Address.new(:kind => "mailing") ) }
    let(:office_location_3) { OfficeLocation.new( :address => Address.new(:kind => "primary") ) }
    subject { Forms::OrganizationSignup.new( :office_locations => [office_location_1, office_location_2, office_location_3]) }

    it "should be invalid" do
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can't have more than one mailing address")
    end
  end

  context "do not give primary office location" do
    let(:office_location_1) { OfficeLocation.new( :address => Address.new(:kind => "mailing") ) }
    subject { Forms::OrganizationSignup.new( :office_locations => [office_location_1]) }

    it "should be invalid" do
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("must select one primary address")
    end
  end

  context "give more than one office location of the branch type" do
    let(:organization) {FactoryGirl.create(:organization)}
    let(:office_location_1) { OfficeLocation.new(organization: organization, :address => FactoryGirl.build(:address, :kind => "branch"), phone: FactoryGirl.build(:phone)) }
    let(:office_location_2) { OfficeLocation.new(organization: organization, :address => FactoryGirl.build(:address, :kind => "branch"), phone: FactoryGirl.build(:phone)) }
    let(:office_location_3) { OfficeLocation.new(organization: organization, :address => FactoryGirl.build(:address, :kind => "primary"), phone: FactoryGirl.build(:phone) ) }

    it "should be valid" do
      subject = Forms::OrganizationSignup.new(legal_name: "asdf", dba: "cas", fein: organization.fein, dob: "2015-1-1", first_name: "aaa", last_name: "bbb", entity_kind: "c_corporation", office_locations: [office_location_1, office_location_2, office_location_3])
      expect(subject.valid?).to be true
    end
  end
end

describe Forms::OrganizationSignup, "fein validation" do
  let(:organization) { FactoryGirl.create(:broker_agency) }
  let(:organization_not_broker) { FactoryGirl.create(:organization) }
  let(:office_location_1) { OfficeLocation.new(organization: organization,
                                                                          :address => FactoryGirl.build(:address, :kind => "primary"), phone: FactoryGirl.build(:phone)) }
  subject { Forms::OrganizationSignup.new( :office_locations => [office_location_1]) }

  around :each do
    DatabaseCleaner.clean
  end

  context "no fein" do
    it "should not be valid" do
      subject = Forms::OrganizationSignup.new(legal_name: "asdf",
                                              dba: "cas",
                                              dob: "2015-1-1",
                                              first_name: "aaa",
                                              last_name: "bbb",
                                              entity_kind: "c_corporation",
                                              office_locations: [office_location_1]
                                              )
      expect(subject.valid?).to be_falsey
      expect(subject).to have_errors_on(:fein)
      expect(subject).not_to have_errors_on(:base)
    end
  end

  context "fein of organization that exists with broker agency profile" do
    it "should not be valid" do
      subject = Forms::OrganizationSignup.new(legal_name: "asdf",
                                              dba: "cas",
                                              dob: "2015-1-1",
                                              fein: organization.fein,
                                              first_name: "aaa",
                                              last_name: "bbb",
                                              entity_kind: "c_corporation",
                                              office_locations: [office_location_1]
                                              )
      expect(subject.valid?).to be_falsey
      expect(subject).to have_errors_on(:base)
      expect(subject.errors[:base]).to eq(["fein is already in use."])
    end
  end

  context "fein of organization that exists without broker agency profile" do
    it "should be valid" do
      subject = Forms::OrganizationSignup.new(legal_name: "asdf",
                                              dba: "cas",
                                              dob: "2015-1-1",
                                              fein: organization_not_broker.fein,
                                              first_name: "aaa",
                                              last_name: "bbb",
                                              entity_kind: "c_corporation",
                                              office_locations: [office_location_1]
                                              )
      expect(subject).to be_valid
      expect(subject).not_to have_errors_on(:base)
    end
  end
end
