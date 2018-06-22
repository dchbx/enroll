require 'rails_helper'
require 'aasm/rspec'

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
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
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

      it "should have a default value of native validation as na" do
        expect(consumer_role.native_validation).to eq "na"
      end

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

        it "should have a state of unverified" do
          expect(consumer_role.aasm_state).to eq "unverified"
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
          expect(consumer_role.aasm_state).to eq "unverified"
        end
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
  let(:family) { FactoryGirl.build(:family)}
  let(:consumer_role) { ConsumerRole.new }
  before :all do
    create_tax_household_for_mikes_family
    @consumer_role = mike.consumer_role
    @taxhouhold = mikes_family.latest_household.tax_households.last
  end

  it "should rerturn active taxhousehold of this year" do
    expect(@consumer_role.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year, mikes_family)).to eq @taxhouhold
  end

  it "should rerturn nil when can not found taxhousehold" do
    expect(consumer_role.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year, family)).to eq nil
  end
end

context "Verification process and notices" do
  let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
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

  describe "Native American verification" do
    shared_examples_for "ensures native american field value" do |action, state, consumer_kind, tribe, tribe_state|
      it "#{action} #{state} for #{consumer_kind}" do
        person.update_attributes!(:tribal_id=>"444444444") if tribe
        person.consumer_role.update_attributes!(:native_validation => tribe_state) if tribe_state
        expect(person.consumer_role.native_validation).to eq(state)
      end
    end
    context "native validation doesn't exist" do
      it_behaves_like "ensures native american field value", "assigns", "na", "NON native american consumer", nil, nil

      it_behaves_like "ensures native american field value", "assigns", "outstanding", "native american consumer", "444444444", nil
    end
    context "existing native validation" do
      it_behaves_like "ensures native american field value", "assigns", "pending", "pending native american consumer", "tribe", "pending"
      it_behaves_like "ensures native american field value", "doesn't change", "outstanding", "outstanding native american consumer", "tribe", "outstanding"
      it_behaves_like "ensures native american field value", "assigns", "outstanding", "na native american consumer", "tribe", "na"
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
      it "returns true if lawful_presence fails and No documents for this type" do
        person.consumer_role.vlp_documents = []
        expect(person.consumer_role.is_type_outstanding?("Citizenship")).to be_truthy
      end
    end

    context "DC Residency" do
      it "returns true if residency status is outstanding and No documents for this type" do
        person.consumer_role.local_residency_validation = "outstanding"
        person.consumer_role.is_state_resident = false
        expect(person.consumer_role.is_type_outstanding?("DC Residency")).to be_truthy
      end

      it "returns false if residency status is attested and No documents for this type" do
        person.consumer_role.local_residency_validation = "attested"
        person.consumer_role.is_state_resident = false
        expect(person.consumer_role.is_type_outstanding?("DC Residency")).to be_falsey
      end
    end

    context "Immigration status" do
      it "returns true if lawful_presence fails and No documents for this type" do
        expect(person.consumer_role.is_type_outstanding?("Immigration status")).to be_truthy
      end
    end

    context "American Indian Status" do
      it "returns true if lawful_presence fails and No documents for this type" do
        expect(person.consumer_role.is_type_outstanding?("American Indian Status")).to be_truthy
      end
    end

    context "always false if documents uploaded for this type" do
      types = ["Social Security Number", "Citizenship", "Immigration status", "American Indian Status"]
      types.each do |type|
        it "returns false for #{type} and documents for this type" do
          person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => type)
          expect(person.consumer_role.is_type_outstanding?(type)).to be_falsey
        end
      end
    end
  end

  describe "#all_types_verified? private" do
    context "only one type is verified" do
      it "returns false if Citizenship/Immigration status unverified" do
        person.consumer_role.ssn_validation = "valid"
        expect(person.consumer_role.send(:all_types_verified?)).to be_falsey
      end

      it "returns false if ssn unverified" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        person.consumer_role.ssn_validation = "invalid"
        expect(person.consumer_role.send(:all_types_verified?)).to be_falsey
      end
    end

    context "all types are verified" do
      it "returns true" do
        person.consumer_role.ssn_validation = "valid"
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(person.consumer_role.send(:all_types_verified?)).to be_truthy
      end
    end

    context "all types are unverified" do
      it "returns true" do
        expect(person.consumer_role.send(:all_types_verified?)).to be_falsey
      end
    end
  end

  describe "update_verification_type private" do
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "hbx" })}
    let(:consumer) { person.consumer_role }
    shared_examples_for "update verification type for consumer" do |verification_type, old_authority, new_authority|
      before do
        consumer.update_attributes(:ssn_validation => "invalid")
        consumer.lawful_presence_determination.deny!(verification_attr)
        consumer.lawful_presence_determination.update_attributes(:vlp_authority => old_authority)
        consumer.update_verification_type(verification_type, "documents in Enroll")
      end
      it "updates #{verification_type}" do
        expect(consumer.is_type_verified?(verification_type)).to eq true
      end

      it "stores correct vlp_authority" do
        expect(consumer.lawful_presence_determination.vlp_authority).to eq new_authority
      end
    end

    it_behaves_like "update verification type for consumer", "Social Security Number", "hbx", "hbx"
    it_behaves_like "update verification type for consumer", "Citizenship", "hbx", "hbx"
    it_behaves_like "update verification type for consumer", "Citizenship", "curam", "hbx"
  end

  describe "#update_all_verification_types private" do
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "curam" })}
    let(:consumer) { person.consumer_role }
    shared_examples_for "update update all verification types for consumer" do |old_authority, new_authority|
      before do
        consumer.update_attributes(:ssn_validation => "invalid")
        consumer.lawful_presence_determination.deny!(verification_attr)
        consumer.lawful_presence_determination.update_attributes(:vlp_authority => old_authority)
        consumer.update_all_verification_types
      end
      it "updates all verification types" do
        expect(consumer.all_types_verified?).to be_truthy
      end
      it "stores correct vlp_authority" do
        expect(consumer.lawful_presence_determination.vlp_authority).to eq new_authority
      end
    end

    it_behaves_like "update update all verification types for consumer", "hbx", "hbx"
    it_behaves_like "update update all verification types for consumer", "admin", "hbx"
    it_behaves_like "update update all verification types for consumer", "curam", "curam"
    it_behaves_like "update update all verification types for consumer", "any", "hbx"
  end

  describe "#admin_verification_action private" do
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "curam" })}
    let(:consumer) { person.consumer_role }
    shared_examples_for "admin verification actions" do |admin_action, v_type, update_reason, upd_attr, result, rejected_field|
      before do
        consumer.admin_verification_action(admin_action, v_type, update_reason)
      end
      it "updates #{v_type} as #{result} if admin clicks #{admin_action}" do
        expect(consumer.send(upd_attr)).to eq result
      end

      if admin_action == "return_for_deficiency"
        it "marks #{v_type} type as rejected" do
          expect(consumer.send(rejected_field)).to be_truthy
        end
      end
    end

    context "verify" do
      it_behaves_like "admin verification actions", "verify", "Social Security Number", "Document in EnrollApp", "ssn_validation", "valid"
      it_behaves_like "admin verification actions", "verify", "Social Security Number", "Document in EnrollApp", "ssn_update_reason", "Document in EnrollApp"
      it_behaves_like "admin verification actions", "verify", "DC Residency", "Document in EnrollApp", "local_residency_validation", "valid"
      it_behaves_like "admin verification actions", "verify", "DC Residency", "Document in EnrollApp", "residency_update_reason", "Document in EnrollApp"

    end

    context "return for deficiency" do
      it_behaves_like "admin verification actions", "return_for_deficiency", "Social Security Number", "Document in EnrollApp", "ssn_validation", "outstanding", "ssn_rejected"
      it_behaves_like "admin verification actions", "return_for_deficiency", "Social Security Number", "Document in EnrollApp", "ssn_update_reason", "Document in EnrollApp", "ssn_rejected"
      it_behaves_like "admin verification actions", "return_for_deficiency", "American Indian Status", "Document in EnrollApp", "native_update_reason", "Document in EnrollApp", "native_rejected"
      it_behaves_like "admin verification actions", "return_for_deficiency", "DC Residency", "Illegible Document", "local_residency_validation", "outstanding", "residency_rejected"
    end
  end

  describe "state machine" do
    let(:consumer) { person.consumer_role }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "hbx" })}
    all_states = [:unverified, :ssa_pending, :dhs_pending, :verification_outstanding, :fully_verified, :sci_verified, :verification_period_ended]
    all_citizen_states = %w(any us_citizen naturalized_citizen alien_lawfully_present lawful_permanent_resident)
    shared_examples_for "IVL state machine transitions and workflow" do |ssn, citizen, residency, from_state, to_state, event|
      before do
        person.ssn = ssn
        consumer.citizen_status = citizen
        consumer.is_state_resident = residency
      end
      it "moves from #{from_state} to #{to_state} on #{event}" do
        expect(consumer).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
      end
    end

    context "import" do
      all_states.each do |state|
        it_behaves_like "IVL state machine transitions and workflow", nil, nil, nil, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", false, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "any", true, state, :fully_verified, "import!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "any", false, state, :fully_verified, "import!"
        it "updates all verification types with callback" do
          consumer.import!
          expect(consumer.all_types_verified?).to eq true
        end
      end
    end

    context "coverage_purchased" do
      describe "citizen with ssn" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", false, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", false, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, :unverified, :ssa_pending, "coverage_purchased!"
      end
      describe "citizen with NO ssn" do
        it_behaves_like "IVL state machine transitions and workflow", nil, "naturalized_citizen", true, :unverified, :dhs_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "naturalized_citizen", false, :unverified, :dhs_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "us_citizen", false, :unverified, :verification_outstanding, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "us_citizen", true, :unverified, :verification_outstanding, "coverage_purchased!"
        it "update ssn with callback fail_ssa_for_no_ssn" do
          allow(person).to receive(:ssn).and_return nil
          allow(consumer).to receive(:citizen_status).and_return "us_citizen"
          consumer.coverage_purchased!
          expect(consumer.ssn_validation).to eq("na")
          expect(consumer.ssn_update_reason).to eq("no_ssn_for_native")
        end
      end
      describe "immigrant with ssn" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", false, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", false, :unverified, :ssa_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, :unverified, :ssa_pending, "coverage_purchased!"
      end
      describe "immigrant with NO ssn" do
        it_behaves_like "IVL state machine transitions and workflow", nil, "alien_lawfully_present", true, :unverified, :dhs_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "alien_lawfully_present", false, :unverified, :dhs_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "lawful_permanent_resident", false, :unverified, :dhs_pending, "coverage_purchased!"
        it_behaves_like "IVL state machine transitions and workflow", nil, "lawful_permanent_resident", true, :unverified, :dhs_pending, "coverage_purchased!"
      end
    end

    context "ssn_invalid" do
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, :ssa_pending, :verification_outstanding, "ssn_invalid!"
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, :ssa_pending, :verification_outstanding, "ssn_invalid!"
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, :ssa_pending, :verification_outstanding, "ssn_invalid!"
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, :ssa_pending, :verification_outstanding, "ssn_invalid!"
      it "fails ssn with callback" do
        consumer.aasm_state = "ssa_pending"
        consumer.ssn_invalid! verification_attr
        expect(consumer.ssn_validation).to eq("outstanding")
      end
      it "fails lawful presence with callback" do
        consumer.aasm_state = "ssa_pending"
        consumer.ssn_invalid! verification_attr
        expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
      end
    end

    context "ssn_valid_citizenship_invalid" do
      describe "citizen" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, :ssa_pending, :verification_outstanding, "ssn_valid_citizenship_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", false, :ssa_pending, :verification_outstanding, "ssn_valid_citizenship_invalid!"
      end
      describe "immigrant" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", false, :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", false, :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
      end

      it "updates ssn validation with callback" do
        consumer.aasm_state = "ssa_pending"
        consumer.ssn_valid_citizenship_invalid! verification_attr
        expect(consumer.ssn_validation).to eq("valid")
      end

      it "fails lawful presence with callback" do
        consumer.aasm_state = "ssa_pending"
        consumer.ssn_valid_citizenship_invalid! verification_attr
        expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
      end

      it "doesn't change user's citizen input" do
        consumer.aasm_state = "ssa_pending"
        consumer.citizen_status = "alien_lawfully_present"
        consumer.ssn_valid_citizenship_invalid! verification_attr
        expect(consumer.lawful_presence_determination.citizen_status).to eq("alien_lawfully_present")
        expect(consumer.lawful_presence_determination.citizenship_result).to eq("not_lawfully_present_in_us")
      end
    end

    context "ssn_valid_citizenship_valid" do
      before :each do
        consumer.lawful_presence_determination.deny! verification_attr
        consumer.citizen_status = "alien_lawfully_present"
      end
      [false, nil, true].each do |residency|
        if residency
          to_state = :fully_verified
        elsif residency.nil?
          to_state = :sci_verified
        else
          to_state = :verification_outstanding
        end
        describe "residency #{residency} #{'pending' if residency.nil?}" do
          [:unverified, :ssa_pending, :verification_outstanding].each do |from_state|
            it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", residency, from_state, to_state, "ssn_valid_citizenship_valid!"
            it "updates ssn citizenship with callback and doesn't change consumer citizen input" do
              consumer.ssn_valid_citizenship_valid! verification_attr
              expect(consumer.ssn_validation).to eq("valid")
              expect(consumer.lawful_presence_determination.verification_successful?).to eq true
              expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
            end
          end
        end
      end
    end

    context "fail_dhs" do
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, :dhs_pending, :verification_outstanding, "fail_dhs!"
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", false, :dhs_pending, :verification_outstanding, "fail_dhs!"
      it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, :dhs_pending, :verification_outstanding, "fail_dhs!"

      it "fails lawful presence with callback" do
        consumer.aasm_state = "dhs_pending"
        consumer.fail_dhs! verification_attr
        expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
      end
    end

    context "pass_dhs" do
      before :each do
        consumer.lawful_presence_determination.deny! verification_attr
        consumer.citizen_status = "alien_lawfully_present"
      end
      [false, nil, true].each do |residency|
        if residency
          to_state = :fully_verified
        elsif residency.nil?
          to_state = :sci_verified
        else
          to_state = :verification_outstanding
        end
        describe "residency #{residency} #{'pending' if residency.nil?}" do
          [:unverified, :dhs_pending, :verification_outstanding].each do |from_state|
            it_behaves_like "IVL state machine transitions and workflow", nil, "naturalized_citizen", residency, from_state, to_state, "pass_dhs!"
            it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", residency, from_state, to_state, "pass_dhs!"
            it "updates citizenship with callback and doesn't change consumer citizen input" do
              consumer.pass_dhs! verification_attr
              expect(consumer.lawful_presence_determination.verification_successful?).to eq true
              expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
            end
          end
        end
      end
    end

    context "pass_residency" do
      [nil, "111111111"].each do |ssn|
        it_behaves_like "IVL state machine transitions and workflow", ssn, "us_citizen", true, :unverified, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, :ssa_pending, :ssa_pending, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, :dhs_pending, :dhs_pending, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, :sci_verified, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :verification_outstanding, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :fully_verified, :verification_outstanding, "fail_residency!"
        it "updates residency status with callback" do
          consumer.is_state_resident = true
          consumer.fail_residency!
          expect(consumer.is_state_resident).to be false
        end
      end
    end

    context "fail_residency" do
      [nil, "111111111"].each do |ssn|
        it_behaves_like "IVL state machine transitions and workflow", ssn, "us_citizen", true, :unverified, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, :ssa_pending, :ssa_pending, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, :dhs_pending, :dhs_pending, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, :sci_verified, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :verification_outstanding, :verification_outstanding, "fail_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :fully_verified, :verification_outstanding, "fail_residency!"
        it "updates residency status with callback" do
          consumer.is_state_resident = true
          consumer.fail_residency! verification_attr
          expect(consumer.is_state_resident).to be false
        end
      end
    end

    context "trigger_residency" do
      [nil, "111111111"].each do |ssn|
        it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, :ssa_pending, :ssa_pending, "trigger_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, :dhs_pending, :dhs_pending, "trigger_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, :sci_verified, :sci_verified, "trigger_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :verification_outstanding, :verification_outstanding, "trigger_residency!"
        it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, :fully_verified, :sci_verified, "trigger_residency!"
        it "updates residency status with callback" do
          if consumer.may_trigger_residency?
            consumer.is_state_resident = true
            consumer.trigger_residency!
            expect(consumer.is_state_resident).to be nil
          end
        end
      end
    end

    context "revert" do
      before :each do
        consumer.import! verification_attr
      end

      all_states.each do |state|
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, state, :unverified, "revert!"
        it "updates ssn" do
          consumer.revert!
          expect(consumer.ssn_validation).to eq "pending"
        end

        it "updates lawful presence status" do
          consumer.revert!
          expect(consumer.lawful_presence_determination.verification_pending?).to eq true
        end
        it "updates residency status" do
          consumer.revert!
          expect(consumer.is_state_resident?).to eq true
        end
      end
    end

    context 'coverage_purchased_no_residency' do
      it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'us_citizen', false, :unverified, :ssa_pending, 'coverage_purchased_no_residency!'
      it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'naturalized_citizen', false, :unverified, :ssa_pending, 'coverage_purchased_no_residency!'
      it_behaves_like 'IVL state machine transitions and workflow', nil, 'alien_lawfully_present', true, :unverified, :dhs_pending, 'coverage_purchased_no_residency!'
      it_behaves_like 'IVL state machine transitions and workflow', nil, 'alien_lawfully_present', false, :unverified, :dhs_pending, 'coverage_purchased_no_residency!'
    end
  end

  describe "#check_for_critical_changes" do
    sensitive_fields = ConsumerRole::VERIFICATION_SENSITIVE_ATTR
    all_fields = FactoryGirl.build(:person, :encrypted_ssn => "111111111", :gender => "male", "updated_by_id": "any").attributes.keys
    mask_hash = all_fields.map{|v| [v, (sensitive_fields.include?(v) ? "call" : "don't call")]}.to_h
    subject { ConsumerRole.new(:person => person) }
    let(:family) { double("Family", :person_has_an_active_enrollment? => true)}
    shared_examples_for "reping the hub fo critical changes" do |field, call, params|
      it "#{call} the hub if #{field} record was changed" do
        allow(Person).to receive(:person_has_an_active_enrollment?).and_return true
        if call == "call"
          expect(subject).to receive(:redetermine_verification!)
        else
          expect(subject).to_not receive(:redetermine_verification!)
        end
        subject.check_for_critical_changes(params, family)
      end
    end
    mask_hash.each do |field, action|
      value = field == "dob" ? "2016-08-08" : "new filed record"
      it_behaves_like "reping the hub fo critical changes", field, action, {field => value}
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

describe "#processing_residency_24h?" do
  let(:consumer_role) {ConsumerRole.new}

  it "returns false if residency determined at attribute is nil" do
    subject = consumer_role.send(:processing_residency_24h?)
    expect(subject).to eq false
  end

  it "returns true if called residency hub today and state resident is nil" do
    consumer_role.update_attributes(is_state_resident: nil, residency_determined_at: DateTime.now)
    subject = consumer_role.send(:processing_residency_24h?)
    expect(subject).to eq true
  end

  it "returns false if residency is already determined in past and state resident is nil" do
    consumer_role.update_attributes(is_state_resident: nil, residency_determined_at: DateTime.now - 2.day)
    subject = consumer_role.send(:processing_residency_24h?)
    expect(subject).to eq false
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

describe "can_trigger_residency?" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:consumer_role) { person.consumer_role }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:enrollment) { double("HbxEnrollment", aasm_state: "coverage_selected")}

  context "when person has age > 19 & has an active coverage" do

    before :each do
      allow(family).to receive(:person_has_an_active_enrollment?).and_return true
    end

    it "should return true if there is a change in address from non-dc to dc" do
      person.update_attributes(no_dc_address: true)
      expect(consumer_role.can_trigger_residency?("false", family)).to eq true
    end

    it "should return false if there is a change in address from dc to non-dc" do
      person.update_attributes(no_dc_address: false)
      expect(consumer_role.can_trigger_residency?("true", family)).to eq false
    end

    it "should return false if there is a change in address from dc to dc" do
      person.update_attributes(no_dc_address: false)
      expect(consumer_role.can_trigger_residency?("false", family)).to eq false
    end

    it "should return false if there is a change in address from non-dc to non-dc" do
      person.update_attributes(no_dc_address: true)
      expect(consumer_role.can_trigger_residency?("true", family)).to eq false
    end
  end

  context "when has an active coverage & address change from non-dc to dc", dbclean: :after_each do

    before do
      person.update_attributes(no_dc_address: true)
      allow(family).to receive(:person_has_an_active_enrollment?).and_return true
    end

    it "should return true if age > 18" do
      expect(consumer_role.can_trigger_residency?("false", family)).to eq true
    end

    it "should return false if age = 18" do
      person.update_attributes(dob: TimeKeeper.date_of_record - 18.years)
      expect(consumer_role.can_trigger_residency?("false", family)).to eq false
    end

    it "should return false if age < 18" do
      consumer_role.person.update_attributes(dob: TimeKeeper.date_of_record - 15.years)
      expect(consumer_role.can_trigger_residency?("false", family)).to eq false
    end
  end

  context "when age > 18 & address change from non-dc to dc" do
    before do
      person.update_attributes(no_dc_address: true)
      allow(family).to receive_message_chain(:active_household, :hbx_enrollments, :where).and_return [enrollment]
    end

    it "should return true if has an active coverage" do
      allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [consumer_role.person]
      expect(consumer_role.can_trigger_residency?("false", family)).to eq true
    end

    it "should return false if no active coverage" do
      allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [nil]
      expect(consumer_role.can_trigger_residency?("false", family)).to eq false
    end
  end
end



describe "is_type_verified?" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:consumer_role) { person.consumer_role }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:enrollment) { double("HbxEnrollment", aasm_state: "coverage_selected")}

  context "when entered type is DC Residency" do


    it "should return true for dc residency verified type" do
      person.update_attributes(no_dc_address: true)
      expect(consumer_role.is_type_verified?("DC Residency")).to eq true
    end
  end

end

RSpec.shared_examples "a consumer role unchanged by ivl_coverage_selected" do |c_state|
  let(:current_state) { c_state }

  describe "in #{c_state} status" do
    it "does not invoke coverage_selected!" do
      expect(subject).not_to receive(:coverage_purchased!)
      subject.ivl_coverage_selected
    end
  end
end

describe ConsumerRole, "receiving a notification of ivl_coverage_selected" do
  let(:person) {Person.new}
  subject { ConsumerRole.new(:aasm_state => current_state, :person => person) }
  describe "in unverified status" do
    let(:current_state) { "unverified" }
    it "fires coverage_selected!" do
      expect(subject).to receive(:coverage_purchased!)
      subject.ivl_coverage_selected
    end
  end

  it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :ssa_pending
  it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :dhs_pending
  it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :verification_outstanding
  it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :fully_verified
  it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :verification_period_ended
end

describe "#add_type_history_element" do
  let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
  let(:attr) { {verification_type: "verification_type",
                action: "action",
                modifier: "actor",
                update_reason: "reason"} }

  it "creates verification history record" do
    person.consumer_role.verification_type_history_elements.delete_all
    person.consumer_role.add_type_history_element(attr)
    expect(person.consumer_role.verification_type_history_elements.size).to be > 0
  end
end

describe "Verification Tracker" do
  let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
  context "mongoid history" do
    it "stores new record with changes" do
      history_tracker_init =  HistoryTracker.count
      person.update_attributes(:first_name => "updated")
      expect(HistoryTracker.count).to be > history_tracker_init
    end
  end

  context "mongoid history extension" do
    it "stores action history element" do
      history_action_tracker_init =  person.consumer_role.history_action_trackers.count
      person.update_attributes(:first_name => "first_name updated", :last_name => "last_name updated")
      person.reload
      expect(person.consumer_role.history_action_trackers.count).to be > history_action_tracker_init
    end

    it "associates history element with mongoid history record" do
      person.update_attributes(:first_name => "first_name updated", :last_name => "last_name updated")
      person.reload
      expect(person.consumer_role.history_action_trackers.last.tracking_record).to be_a(HistoryTracker)
    end
  end
end
