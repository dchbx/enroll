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

describe "#find_ridp_document_by_key" do
  let(:person) {Person.new}
  let(:consumer_role) {ConsumerRole.new({person:person})}
  let(:key) {"sample-key"}
  let(:ridp_document) {RidpDocument.new({subject: "Certificate of Citizenship", identifier:"urn:openhbx:terms:v1:file_storage:s3:bucket:bucket_name##{key}"})}

  context "has a ridp_document without a file uploaded" do
    before do
      consumer_role.ridp_documents.build({subject: "Certificate of Citizenship"})
    end

    it "return no document" do
      found_document = consumer_role.find_ridp_document_by_key(key)
      expect(found_document).to be_nil
    end
  end

  context "has a ridp_document with a file uploaded" do
    before do
      consumer_role.ridp_documents << ridp_document
    end

    it "returns ridp_document document" do
      found_document = consumer_role.find_ridp_document_by_key(key)
      expect(found_document).to eql(ridp_document)
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

  describe "#has_ridp_docs_for_type?" do
    before do
      person.consumer_role.ridp_documents=[]
    end
    context "ridp exist but document is NOT uploaded" do
      it "returns false for ridp doc without uploaded copy" do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :identifier => nil )
        expect(person.consumer_role.has_ridp_docs_for_type?("Identity")).to be_falsey
      end
      it "returns false for Identity type" do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :identifier => nil, :ridp_verification_type  => "Identity")
        expect(person.consumer_role.has_ridp_docs_for_type?("Identity")).to be_falsey
      end
    end
    context "ridp with uploaded copy" do
      it "returns true if person has uploaded documents for this type" do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :identifier => "identifier", :ridp_verification_type  => "Identity")
        expect(person.consumer_role.has_ridp_docs_for_type?("Identity")).to be_truthy
      end
      it "returns false if person has NO documents for this type" do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :identifier => "identifier", :ridp_verification_type  => "Identity")
        expect(person.consumer_role.has_ridp_docs_for_type?("Identity")).to be_truthy
      end
    end
  end

  describe "Native American verification" do
    shared_examples_for "ensures native american field value" do |action, state, consumer_kind, tribe, tribe_state|
      it "#{action} #{state} for #{consumer_kind}" do
        person.update_attributes!(:tribal_id => tribe)
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

  describe "update_ridp_verification_type private" do
    let(:consumer) { person.consumer_role }
    shared_examples_for "update ridp verification type for consumer" do |verification_type, reason|
      before do
        consumer.update_ridp_verification_type(verification_type, reason)
      end
      it "updates #{verification_type}" do
        expect(consumer.identity_verified?).to eq true
      end
    end

    it_behaves_like "update ridp verification type for consumer", "Identity", "documents in Enroll"
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

  describe "#admin_ridp_verification_action private" do
    let(:consumer) { person.consumer_role }
    shared_examples_for "admin ridp verification actions" do |admin_action, v_type, update_reason, upd_attr, result, rejected_field|
      before do
        consumer.admin_ridp_verification_action(admin_action, v_type, update_reason)
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

    it_behaves_like "admin ridp verification actions", "verify", "Identity", "Document in EnrollApp", "identity_validation", "valid"
    it_behaves_like "admin ridp verification actions", "return_for_deficiency", "Identity", "Document in EnrollApp", "identity_validation", "outstanding", "identity_rejected"

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

    it_behaves_like "admin verification actions", "verify", "Social Security Number", "Document in EnrollApp", "ssn_validation", "valid"
    it_behaves_like "admin verification actions", "return_for_deficiency", "Social Security Number", "Document in EnrollApp", "ssn_validation", "outstanding", "ssn_rejected"
    it_behaves_like "admin verification actions", "verify", "Social Security Number", "Document in EnrollApp", "ssn_update_reason", "Document in EnrollApp"
    it_behaves_like "admin verification actions", "return_for_deficiency", "Social Security Number", "Document in EnrollApp", "ssn_update_reason", "Document in EnrollApp", "ssn_rejected"
    it_behaves_like "admin verification actions", "return_for_deficiency", "American Indian Status", "Document in EnrollApp", "native_update_reason", "Document in EnrollApp", "native_rejected"

  end

  describe "state machine" do
    let(:consumer) { person.consumer_role }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "hbx" })}
    all_states = [:unverified, :ssa_pending, :dhs_pending, :verification_outstanding, :fully_verified, :verification_period_ended]
    context "import" do
      before do
        person.consumer_role.update_attributes(:ssn_validation => "invalid")
      end
      all_states.each do |state|
        it "changes #{state} to fully_verified" do
          expect(consumer).to transition_from(state).to(:fully_verified).on_event(:import)
          expect(consumer.all_types_verified?).to eq true
        end
      end
    end

    context "coverage_purchased" do
      it "changes state to dhs_pending on coverage_purchased! for non_native without ssn" do
        person.ssn=nil
        consumer.citizen_status = "non_native_citizen"
        expect(consumer).to transition_from(:unverified).to(:dhs_pending).on_event(:coverage_purchased)
      end

      it "changes state to ssa_pending on coverage_purchased! for non_native with SSN" do
        consumer.citizen_status = "non_native_citizen"
        expect(consumer).to transition_from(:unverified).to(:ssa_pending).on_event(:coverage_purchased)
      end

      it "changes state to ssa_pending on coverage_purchased! for native" do
        expect(consumer).to transition_from(:unverified).to(:ssa_pending).on_event(:coverage_purchased)
      end

      it "changes state to outstanding for native consumer with NO ssn without calling hub" do
        person.ssn=nil
        expect(consumer).to transition_from(:unverified).to(:verification_outstanding).on_event(:coverage_purchased)
        expect(consumer.ssn_validation).to eq("na")
        expect(consumer.ssn_update_reason).to eq("no_ssn_for_native")
      end
    end

    context "ssn_invalid" do
      it "changes state to verification_outstanding" do
        expect(consumer).to transition_from(:ssa_pending).to(:verification_outstanding).on_event(:ssn_invalid, verification_attr)
        expect(consumer.ssn_validation).to eq("outstanding")
      end
    end

    context "ssn_valid_citizenship_invalid" do
      it "changes state to verification_outstanding for native citizen" do
        expect(consumer).to transition_from(:ssa_pending).to(:verification_outstanding).on_event(:ssn_valid_citizenship_invalid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
      end
      it "changes state to dhs_pending for non native citizen" do
        consumer.citizen_status = "alien_lawfully_present"
        expect(consumer).to transition_from(:ssa_pending).to(:dhs_pending).on_event(:ssn_valid_citizenship_invalid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        #check that user's input was not overwritten
        expect(consumer.lawful_presence_determination.citizen_status).to eq("alien_lawfully_present")
        expect(consumer.lawful_presence_determination.citizenship_result).to eq("not_lawfully_present_in_us")
      end
    end

    context "ssn_valid_citizenship_valid" do
      before :each do
        consumer.lawful_presence_determination.deny! verification_attr
        consumer.citizen_status = "alien_lawfully_present"
      end
      it "changes state to fully_verified from unverified for native citizen or non native with ssn" do
        expect(consumer).to transition_from(:unverified).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
        #check that user's input was not overwritten
        expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
      end
      it "changes state to fully_verified from ssa_pending" do
        expect(consumer).to transition_from(:ssa_pending).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
        #check that user's input was not overwritten
        expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
      end
      it "changes state to fully_verified from verification_outstanding" do
        expect(consumer).to transition_from(:verification_outstanding).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
        #check that user's input was not overwritten
        expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
      end
      it "changes state to fully_verified from fully_verified" do
        expect(consumer).to transition_from(:fully_verified).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
        #check that user's input was not overwritten
        expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
      end
    end

    context "fail_dhs" do
      it "changes state from dhs_pending to verification_outstanding" do
        expect(consumer).to transition_from(:dhs_pending).to(:verification_outstanding).on_event(:fail_dhs, verification_attr)
        expect(consumer.lawful_presence_determination.verification_outstanding?).to eq true
      end

    end

    context "pass_dhs" do
      before :each do
        consumer.lawful_presence_determination.deny! verification_attr
      end
      it "changes state from dhs_pending to fully_verified" do
        person.ssn=nil
        consumer.citizen_status = "non_native_citizen"
        expect(consumer).to transition_from(:unverified).to(:fully_verified).on_event(:pass_dhs, verification_attr)
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end
      it "changes state from dhs_pending to fully_verified" do
        expect(consumer).to transition_from(:dhs_pending).to(:fully_verified).on_event(:pass_dhs, verification_attr)
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end
      it "changes state from dhs_pending to fully_verified" do
        expect(consumer).to transition_from(:verification_outstanding).to(:fully_verified).on_event(:pass_dhs, verification_attr)
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end

    end

    context "reject" do
      before :each do
        consumer.lawful_presence_determination.authorize! verification_attr
      end
      all_states.each do |state|
        it "change #{state} to verification_outstanding" do
          expect(consumer).to transition_from(state).to(:verification_outstanding).on_event(:reject, verification_attr)
        end
      end
    end

    context "revert" do
      before :each do
        consumer.lawful_presence_determination.authorize! verification_attr
      end
      all_states.each do |state|
        it "change #{state} to unverified" do
          expect(consumer).to transition_from(state).to(:unverified).on_event(:revert, verification_attr)
          expect(consumer.lawful_presence_determination.verification_pending?).to eq true
        end
      end
    end

    context "redetermine" do
      before :each do
        consumer.lawful_presence_determination.authorize! verification_attr
      end
      all_states.each do |state|
        it "change #{state} to ssa_pending if SSA applied" do
          expect(consumer).to transition_from(state).to(:ssa_pending).on_event(:redetermine, verification_attr)
          expect(consumer.lawful_presence_determination.verification_pending?).to eq true
        end

        it "change #{state} to dhs_pending if DHS applied" do
          person.ssn=nil
          consumer.citizen_status = "non_native_citizen"
          expect(consumer).to transition_from(state).to(:dhs_pending).on_event(:redetermine, verification_attr)
          expect(consumer.lawful_presence_determination.verification_pending?).to eq true
        end
      end
    end
  end

  describe "#check_for_critical_changes" do
    sensitive_fields = ConsumerRole::VERIFICATION_SENSITIVE_ATTR
    all_fields = FactoryGirl.build(:person, :encrypted_ssn => "111111111", :gender => "male", "updated_by_id": "any").attributes.keys
    mask_hash = all_fields.map{|v| [v, (sensitive_fields.include?(v) ? "call" : "don't call")]}.to_h
    subject { ConsumerRole.new(:person => person) }
    shared_examples_for "reping the hub fo critical changes" do |field, call, params|
      it "#{call} the hub if #{field} record was changed" do
        allow(Person).to receive(:person_has_an_active_enrollment?).and_return true
        if call == "call"
          expect(subject).to receive(:redetermine!)
        else
          expect(subject).to_not receive(:redetermine!)
        end
        subject.check_for_critical_changes(params)
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
