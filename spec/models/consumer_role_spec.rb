require 'rails_helper'

describe ConsumerRole, dbclean: :after_each do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:no_ssn).to :person}
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should delegate_method(:is_incarcerated).to :person }

  it { should delegate_method(:race).to :person }
  it { should delegate_method(:ethnicity).to :person }
  it { should delegate_method(:is_disabled).to :person }

  it { should validate_presence_of :gender }
  it { should validate_presence_of :dob }

  let(:address)       {FactoryGirl.build(:address)}
  let(:saved_person)  {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789")}
  let(:saved_person_no_ssn)  {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "", no_ssn: '1')}
  let(:saved_person_no_ssn_invalid)  {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "", no_ssn: '0')}
  let(:is_applicant)          { true }
  let(:citizen_error_message) { "test citizen_status is not a valid citizen status" }

  describe ".new" do
    let(:valid_params) do
      {
        is_applicant: is_applicant,
        person: saved_person
      }
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect(ConsumerRole.new(**params).valid?).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:consumer_role) { saved_person.build_consumer_role(valid_params) }

      it "should save" do
        expect(consumer_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          consumer_role.save
        end

        it "should be findable" do
          expect(ConsumerRole.find(consumer_role.id).id).to eq consumer_role.id
        end

        it "should have a state of verifications_pending" do
          expect(consumer_role.aasm_state).to eq "verifications_pending"
        end
      end
    end

    context "with all valid arguments including no ssn" do
      let(:consumer_role) { saved_person_no_ssn.build_consumer_role(valid_params) }

      it "should save" do
        expect(consumer_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          consumer_role.save
        end

        it "should be findable" do
          expect(ConsumerRole.find(consumer_role.id).id).to eq consumer_role.id
        end

        it "should have a state of verifications_pending" do
          expect(consumer_role.aasm_state).to eq "verifications_pending"
        end
      end
    end

    #context "with invalid arguments  no ssn" do
    #  let(:consumer_role) { saved_person_no_ssn_invalid.build_consumer_role(valid_params) }

    #  it "should not save" do
    #    expect(consumer_role.save).to be_falsey
    #  end
    #end

    # context "with no is_incarcerated" do
    #   let(:params) {valid_params.except(:is_incarcerated)}

    #   it "should fail validation " do
    #     expect(ConsumerRole.create(**params).errors[:is_incarcerated].any?).to be_truthy
    #   end
    # end

    # context "with no is_applicant" do
    #   let(:params) {valid_params.except(:is_applicant)}
    #   it "should fail validation" do
    #     expect(ConsumerRole.create(**params).errors[:is_applicant].any?).to be_truthy
    #   end
    # end

    # context "with no citizen_status" do
    #   let(:params) {valid_params.except(:citizen_status)}
    #   it "should fail validation" do
    #     expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
    #   end
    # end

    # context "with improper citizen_status" do
    #   let(:params) {valid_params.deep_merge({citizen_status: "test citizen_status"})}
    #   it "should fail validation with improper citizen_status" do
    #     expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
    #     expect(ConsumerRole.create(**params).errors[:citizen_status]).to eq [citizen_error_message]

    #   end
    # end
  end

end

shared_examples_for "a ConsumerRole which hasn't left pending verifications" do
  it "should still be in verifications_pending" do
    expect(subject.verifications_pending?).to eq true
  end
end

describe ConsumerRole, "in the verifications_pending state" do
  subject { ConsumerRole.new(:aasm_state => :verifications_pending) }
    before(:each) do
      allow(CoverageHousehold).to receive(:update_individual_eligibilities_for).with(subject)
    end

  describe "with residency authorized" do
    before(:each) do
      subject.is_state_resident = true
    end
    describe "when lawful_presence fails" do
      let(:mock_lp_denial) { double({ :determined_at => Time.now, :vlp_authority => "ssa" }) }
      before(:each) do
        subject.is_state_resident = true
        subject.deny_lawful_presence(mock_lp_denial)
      end
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end

    describe "instructed to start the eligibility process" do
      let(:person) { Person.new }
      let(:requested_start_date) { double }

      before(:each) do
        subject.person = person
      end

      it "should trigger lawful presence determination only " do
        expect(subject.lawful_presence_determination).to receive(:start_determination_process).with(requested_start_date)
        expect(subject).not_to receive(:notify).with(ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => person})
        subject.start_individual_market_eligibility!(requested_start_date)
      end
    end

  end

  describe "with residency denied" do
    before(:each) do
      subject.is_state_resident = false
    end
    describe "when lawful_presence fails" do
      let(:mock_lp_denial) { double({ :determined_at => Time.now, :vlp_authority => "ssa" }) }
      before(:each) do
        subject.is_state_resident = true
        subject.deny_lawful_presence(mock_lp_denial)
      end
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end
  end

  describe "with lawful_presence authorized" do
    before :each do
      subject.lawful_presence_determination = LawfulPresenceDetermination.new(
        :aasm_state => :verification_successful
      )
    end
    describe "when residency fails" do
      before(:each) do
        subject.deny_residency
      end
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end

    describe "instructed to start the eligibility process" do
      let(:person) { Person.new }
      let(:requested_start_date) { double }

      before(:each) do
        subject.person = person
      end

      it "should trigger local residency determination only " do
        expect(subject.lawful_presence_determination).not_to receive(:start_determination_process).with(requested_start_date)
        expect(subject).to receive(:notify).with(ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => person})
        subject.start_individual_market_eligibility!(requested_start_date)
      end
    end
  end

  describe "with lawful_presence failed" do
    before :each do
      subject.lawful_presence_determination = LawfulPresenceDetermination.new(
        :aasm_state => :verification_outstanding
      )
    end
    describe "when residency fails" do
      before(:each) do
        subject.deny_residency
      end
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end
  end

  describe "with residency and lawful_presence pending" do
    describe "instructed to start the eligibility process" do
      let(:person) { Person.new }
      let(:requested_start_date) { double }

      before(:each) do
        subject.person = person
      end

      it "should trigger both eligibility processes when individual eligibility is triggered" do
        expect(subject.lawful_presence_determination).to receive(:start_determination_process).with(requested_start_date)
        expect(subject).to receive(:notify).with(ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => person})
        subject.start_individual_market_eligibility!(requested_start_date)
      end
    end

    describe "which fails residency" do
      before(:each) do
        subject.deny_residency
      end
      it_should_behave_like "a ConsumerRole which hasn't left pending verifications"
    end

    describe "which passes residency" do
      before(:each) do
        subject.authorize_residency
      end
      it_should_behave_like "a ConsumerRole which hasn't left pending verifications"
    end

    describe "which fails lawful_presence" do
      let(:mock_lp_denial) { double({ :determined_at => Time.now, :vlp_authority => "ssa" }) }
      before(:each) do
        subject.deny_lawful_presence(mock_lp_denial)
      end
      it_should_behave_like "a ConsumerRole which hasn't left pending verifications"
    end

    describe "which passes lawful_presence" do
      let(:mock_lp_approval) { double({ :determined_at => Time.now, :vlp_authority => "ssa", :citizen_status => "a mock citizen status" }) }
      before(:each) do
        subject.authorize_lawful_presence(mock_lp_approval)
      end
      it_should_behave_like "a ConsumerRole which hasn't left pending verifications"
    end

    describe "when both residency and lawful presence fail" do
      let(:mock_lp_denial) { double({ :determined_at => Time.now, :vlp_authority => "ssa" }) }
      before(:each) do
        subject.deny_residency
        subject.deny_lawful_presence(mock_lp_denial)
      end

      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end

    describe "when both residency and lawful presence are authorized" do
      let(:mock_lp_approval) { double({ :determined_at => Time.now, :vlp_authority => "ssa", :citizen_status => "a mock citizen status" }) }
      before(:each) do
        subject.authorize_residency
        subject.authorize_lawful_presence(mock_lp_approval)
      end

      it "should be fully_verified" do
        expect(subject.fully_verified?).to eq true
      end
    end
  end
end

describe ConsumerRole, "in the verifications_outstanding state" do
  subject { ConsumerRole.new(:aasm_state => :verifications_outstanding, :lawful_presence_determination => lawful_presence_determination, :is_state_resident => state_resident_value) }

  before(:each) do
    allow(CoverageHousehold).to receive(:update_individual_eligibilities_for).with(subject)
  end

  describe "with a failed residency, and successful lawful presence" do
    let(:lawful_presence_determination) {
      LawfulPresenceDetermination.new(
        :aasm_state => :verification_successful
      )
    }
    let(:state_resident_value) { false }
    describe "when residency is authorized" do
      before :each do
        subject.authorize_residency
      end
      it "should be fully_verified" do
        expect(subject.fully_verified?).to eq true
      end
    end
  end

  describe "with a successful residency, and failed lawful presence" do
    let(:lawful_presence_determination) {
      LawfulPresenceDetermination.new(
        :aasm_state => :verification_outstanding
      )
    }
    let(:state_resident_value) { true }
    describe "when lawful_presence is authorized" do
      let(:mock_lp_approval) { double({ :determined_at => Time.now, :vlp_authority => "ssa", :citizen_status => "a mock citizen status" }) }
      before(:each) do
        subject.authorize_lawful_presence(mock_lp_approval)
      end
      it "should be fully_verified" do
        expect(subject.fully_verified?).to eq true
      end
    end
  end

  describe "with a failed residency and failed lawful_presence" do
    let(:lawful_presence_determination) {
      LawfulPresenceDetermination.new(
        :aasm_state => :verification_outstanding
      )
    }
    let(:state_resident_value) { false }
    describe "when residency is authorized" do
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end
    describe "when lawful_presence is authorized" do
      let(:mock_lp_approval) { double({ :determined_at => Time.now, :vlp_authority => "ssa", :citizen_status => "a mock citizen status" }) }
      before(:each) do
        subject.authorize_lawful_presence(mock_lp_approval)
      end
      it "should be in verifications_outstanding" do
        expect(subject.verifications_outstanding?).to eq true
      end
    end
    describe "when both residency and lawful presence are authorized" do
      let(:mock_lp_approval) { double({ :determined_at => Time.now, :vlp_authority => "ssa", :citizen_status => "a mock citizen status" }) }
      before(:each) do
        subject.authorize_residency
        subject.authorize_lawful_presence(mock_lp_approval)
      end

      it "should be fully_verified" do
        expect(subject.fully_verified?).to eq true
      end

    end
  end
end

describe "#find_document" do
  let(:consumer_role) {ConsumerRole.new}
  context "consumer role does not have any vlp_documents" do
    it "it creates and returns an empty document of given subject" do
      doc = consumer_role.find_document("Certificate of Citizenship")
      expect(doc).to be_a_kind_of(VlpDocument)
      expect(doc.subject).to eq("Certificate of Citizenship")
    end
  end

  context "consumer role has a vlp_document" do
    it "it returns the document" do
      document = consumer_role.vlp_documents.build({subject: "Certificate of Citizenship"})
      found_document = consumer_role.find_document("Certificate of Citizenship")
      expect(found_document).to be_a_kind_of(VlpDocument)
      expect(found_document).to eq(document)
      expect(found_document.subject).to eq("Certificate of Citizenship")
    end
  end
end

describe "#find_vlp_document_by_key" do
  let(:person) {Person.new}
  let(:consumer_role) {ConsumerRole.new({person:person})}
  let(:key) {"sample-key"}
  let(:vlp_document) {VlpDocument.new({subject: "Certificate of Citizenship", identifier:"urn:openhbx:terms:v1:file_storage:s3:bucket:bucket_name##{key}"})}

  context "has a vlp_document without a file uploaded" do
    before do
      consumer_role.vlp_documents.build({subject: "Certificate of Citizenship"})
    end

    it "return no document" do
      found_document = consumer_role.find_vlp_document_by_key(key)
      expect(found_document).to be_nil
    end
  end

  context "has a vlp_document with a file uploaded" do
    before do
      consumer_role.vlp_documents << vlp_document
    end

    it "returns vlp_document document" do
      found_document = consumer_role.find_vlp_document_by_key(key)
      expect(found_document).to eql(vlp_document)
    end
  end
end

describe "#build_nested_models_for_person" do
  let(:person) {FactoryGirl.create(:person)}
  let(:consumer_role) {ConsumerRole.new}

  before do
    allow(consumer_role).to receive(:person).and_return person
    consumer_role.build_nested_models_for_person
  end

  it "should get home and mailing address" do
    expect(person.addresses.map(&:kind)).to include "home"
    expect(person.addresses.map(&:kind)).to include 'mailing'
  end

  it "should get home and mobile phone" do
    expect(person.phones.map(&:kind)).to include "home"
    expect(person.phones.map(&:kind)).to include "mobile"
  end

  it "should get emails" do
    Email::KINDS.each do |kind|
      expect(person.emails.map(&:kind)).to include kind
    end
  end
end

describe "#latest_active_tax_household_with_year" do
  include_context "BradyBunchAfterAll"
  before :all do
    create_tax_household_for_mikes_family
    @consumer_role = mike.consumer_role
    @taxhouhold = mikes_family.latest_household.tax_households.last
  end

  it "should rerturn active taxhousehold of this year" do
    expect(@consumer_role.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year)).to eq @taxhouhold
  end

  it "should rerturn nil when can not found taxhousehold" do
    expect(ConsumerRole.new.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year)).to eq nil
  end
end

context "Verification process and notices" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  describe "#has_docs_for_type?" do
    before do
      person.consumer_role.vlp_documents=[]
    end
    context "vlp exist but document is NOT uploaded" do
      it "returns false for vlp doc without uploaded copy" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :identifier => nil )
        expect(person.consumer_role.has_docs_for_type?("Citizenship")).to be_falsey
      end
      it "returns false for Immigration type" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :identifier => nil, :verification_type  => "Immigration type")
        expect(person.consumer_role.has_docs_for_type?("Immigration type")).to be_falsey
      end
    end
    context "vlp with uploaded copy" do
      it "returns true if person has uploaded documents for this type" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :identifier => "identifier", :verification_type  => "Citizenship")
        expect(person.consumer_role.has_docs_for_type?("Citizenship")).to be_truthy
      end
      it "returns false if person has NO documents for this type" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :identifier => "identifier", :verification_type  => "Immigration type")
        expect(person.consumer_role.has_docs_for_type?("Immigration type")).to be_truthy
      end
    end
  end

  describe "#is_type_outstanding?" do
    context "Social Security Number" do
      it "returns true for unverified ssn and NO docs uploaded for this type" do
        person.consumer_role.ssn_validation = "ne"
        expect(person.consumer_role.is_type_outstanding?("Social Security Number")).to be_truthy
      end
      it "return false if documents uploaded" do
        person.consumer_role.ssn_validation = "ne"
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Social Security Number")
        expect(person.consumer_role.is_type_outstanding?("Social Security Number")).to be_falsey
      end
      it "return false for verified ssn" do
        person.consumer_role.ssn_validation = "valid"
        expect(person.consumer_role.is_type_outstanding?("Social Security Number")).to be_falsey
      end
    end
    context "Citizenship" do
      it "returns true for if lawful_presence fails and No documents for this type" do
        person.consumer_role.vlp_documents = []
        expect(person.consumer_role.is_type_outstanding?("Citizenship")).to be_truthy
      end
    end
    context "Immigration status" do
      it "returns true for if lawful_presence fails and No documents for this type" do
        expect(person.consumer_role.is_type_outstanding?("Immigration status")).to be_truthy
      end
    end

    context "always false if documents uploaded for this type" do
      types = ["Social Security Number", "Citizenship", "Immigration status"]
      types.each do |type|
        it "returns false for #{type} and documents for this type" do
          person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => type)
          expect(person.consumer_role.is_type_outstanding?(type)).to be_falsey
        end
      end
    end
  end
end

