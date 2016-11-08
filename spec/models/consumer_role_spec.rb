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

  describe "Native American verification" do
    shared_examples_for "ensures native american field value" do |action, state, consumer_kind, tribe, tribe_state|
      it "#{action} #{state} for #{consumer_kind}" do
        person.update_attributes!(:citizen_status=>"indian_tribe_member") if tribe
        person.consumer_role.update_attributes!(:native_validation => tribe_state) if tribe_state
        expect(person.consumer_role.native_validation).to eq(state)
      end
    end
    context "native validation doesn't exist" do
      it_behaves_like "ensures native american field value", "assigns", "na", "NON native american consumer"

      it_behaves_like "ensures native american field value", "assigns", "outstanding", "native american consumer", "tribe"
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

  describe "state machine" do
    let(:consumer) { person.consumer_role }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :authority => "hbx" })}
    all_states = [:unverified, :ssa_pending, :dhs_pending, :verification_outstanding, :fully_verified, :verification_period_ended]
    context "import" do
      all_states.each do |state|
        it "changes #{state} to fully_verified" do
          expect(consumer).to transition_from(state).to(:fully_verified).on_event(:import)
        end
      end
    end

    context "coverage_purchased" do
      it "changes state to dhs_pending on coverage_purchased! for non_native without ssn" do
        person.ssn=nil
        consumer.citizen_status = "not_us"
        expect(consumer).to transition_from(:unverified).to(:dhs_pending).on_event(:coverage_purchased)
      end

      it "changes state to ssa_pending on coverage_purchased! for non_native with SSN" do
        consumer.citizen_status = "not_us"
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
        consumer.citizen_status = "not_us"
        expect(consumer).to transition_from(:ssa_pending).to(:dhs_pending).on_event(:ssn_valid_citizenship_invalid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.citizen_status).to eq("non_native_not_lawfully_present_in_us")
        expect(consumer.lawful_presence_determination.citizenship_result).to eq("not_lawfully_present_in_us")
      end
    end

    context "ssn_valid_citizenship_valid" do
      before :each do
        consumer.lawful_presence_determination.deny! verification_attr
      end
      it "changes state to fully_verified from unverified for native citizen or non native with ssn" do
        expect(consumer).to transition_from(:unverified).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end
      it "changes state to fully_verified from ssa_pending" do
        expect(consumer).to transition_from(:ssa_pending).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end
      it "changes state to fully_verified from verification_outstanding" do
        expect(consumer).to transition_from(:verification_outstanding).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
      end
      it "changes state to fully_verified from fully_verified" do
        expect(consumer).to transition_from(:fully_verified).to(:fully_verified).on_event(:ssn_valid_citizenship_valid, verification_attr)
        expect(consumer.ssn_validation).to eq("valid")
        expect(consumer.lawful_presence_determination.verification_successful?).to eq true
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
        consumer.citizen_status = "not_us"
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
          consumer.citizen_status = "not_us"
          expect(consumer).to transition_from(state).to(:dhs_pending).on_event(:redetermine, verification_attr)
          expect(consumer.lawful_presence_determination.verification_pending?).to eq true
        end
      end
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
  subject { ConsumerRole.new(:aasm_state => current_state) }
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
