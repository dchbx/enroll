require "rails_helper"

RSpec.describe VerificationHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  before :each do
    assign(:person, person)
  end
  describe "#doc_status_label" do
    doc_status_array = VlpDocument::VLP_DOCUMENTS_VERIF_STATUS
    doc_status_classes = ["warning", "default", "success", "danger"]
    doc_status_array.each_with_index do |doc_verif_status, index|
      context "doc status is #{doc_verif_status}" do
        let(:document) { FactoryGirl.build(:vlp_document, :status=>doc_verif_status) }
        it "returns #{doc_status_classes[index]} class for #{doc_verif_status} document status" do
          expect(helper.doc_status_label(document)).to eq doc_status_classes[index]
        end
      end
    end
  end

  describe "#verification_type_status" do
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "hbx" })}
    let(:types) { ["Social Security Number", "Citizenship", "Immigration status", "American Indian Status"] }
    shared_examples_for "verification type status" do |current_state, verification_type, uploaded_doc, status, curam, admin|
      before do
        uploaded_doc ? person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => verification_type) : person.consumer_role.vlp_documents = []
        person.consumer_role.revert!(verification_attr) unless current_state
        if curam
          person.consumer_role.import!(verification_attr) if current_state == "valid"
          person.consumer_role.vlp_authority = "curam"
        else
          if current_state == "valid"
            person.consumer_role.ssn_validation = "valid"
            person.consumer_role.native_validation = "valid"
            person.consumer_role.lawful_presence_determination.authorize!(verification_attr)
          else
            person.consumer_role.ssn_validation = "outstanding"
            person.consumer_role.native_validation = "outstanding"
            person.consumer_role.lawful_presence_determination.deny!(verification_attr)
          end
        end
      end
      it "returns #{status} status for #{verification_type} #{uploaded_doc ? 'with uploaded doc' : 'without uploaded docs'}" do
        expect(helper.verification_type_status(verification_type, person, admin)).to eq status
      end
    end

    context "consumer role" do
      it_behaves_like "verification type status", "outstanding", "Social Security Number", false, "outstanding", false, false
      it_behaves_like "verification type status", "valid", "Social Security Number", false, "verified", false, false
      it_behaves_like "verification type status", "outstanding", "Social Security Number", true, "in review", false, false
      it_behaves_like "verification type status", "outstanding", "American Indian Status", false, "outstanding", false, false
      it_behaves_like "verification type status", "valid", "American Indian Status", false, "verified", false, false
      it_behaves_like "verification type status", "outstanding", "American Indian Status", true, "in review", false, false
      it_behaves_like "verification type status", "outstanding", "Citizenship", false, "outstanding", false, false
      it_behaves_like "verification type status", "valid", "Citizenship", false, "verified", false, false
      it_behaves_like "verification type status", "outstanding", "Citizenship", true, "in review", false, false
      it_behaves_like "verification type status", "outstanding", "Immigration status", false, "outstanding", false, false
      it_behaves_like "verification type status", "valid", "Immigration status", false, "verified", false, false
      it_behaves_like "verification type status", "outstanding", "Immigration status", true, "in review", false, false
      it_behaves_like "verification type status", "valid", "Immigration status", true, "verified", "curam", false
    end

    context "admin role" do
      it_behaves_like "verification type status", "valid", "Immigration status", true, "curam", "curam", "admin"
      it_behaves_like "verification type status", "valid", "Social Security Number", false, "verified", false, "admin"
      it_behaves_like "verification type status", "valid", "Citizenbship", true, "curam", "curam", "admin"
      it_behaves_like "verification type status", "outstanding", "American Indian Status", false, "outstanding", "curam", "admin"
    end
  end

  describe '#ridp_type_status' do
    let(:types) { ['Identity', 'Application'] }
    shared_examples_for 'ridp type status' do |current_state, ridp_type, uploaded_doc, status|
      before do
        uploaded_doc ? person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => ridp_type) : person.consumer_role.ridp_documents = []
        if current_state == "valid"
          person.consumer_role.identity_validation = "valid"
          person.consumer_role.application_validation = "valid"
        else
          person.consumer_role.identity_validation = "outstanding"
          person.consumer_role.application_validation = "outstanding"
        end
      end
      it "returns #{status} status for #{ridp_type} #{uploaded_doc ? 'with uploaded doc' : 'without uploaded docs'}" do
        expect(helper.ridp_type_status(ridp_type, person)).to eq status
      end
    end
    context 'consumer role' do
      it_behaves_like 'ridp type status', 'outstanding', 'Identity', false, 'outstanding'
      it_behaves_like 'ridp type status', 'valid', 'Identity', false, 'valid'
      it_behaves_like 'ridp type status', 'outstanding', 'Identity', true, 'in review'
      it_behaves_like 'ridp type status', 'outstanding', 'Application', false, 'outstanding'
      it_behaves_like 'ridp type status', 'valid', 'Application', false, 'valid'
      it_behaves_like 'ridp type status', 'outstanding', 'Application', true, 'in review'
    end
  end


  describe "#verification_type_class" do
    context "verification type status verified" do
      it "returns success SSN verified" do
        person.consumer_role.ssn_validation = "valid"
        expect(helper.verification_type_class("Social Security Number", person)).to eq("success")
      end

      it "returns success for Citizenship verified" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(helper.verification_type_class("Citizenship", person)).to eq("success")
      end

      it "returns success for Immigration status verified" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(helper.verification_type_class("Immigration status", person)).to eq("success")
      end

      it "returns success for American Indian status verified" do
        person.consumer_role.native_validation = "valid"
        expect(helper.verification_type_class("American Indian Status", person)).to eq("success")
      end
    end

    context "verification type status in review" do
      it "returns warning for SSN outstanding with docs" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Social Security Number")
        expect(helper.verification_type_class("Social Security Number", person)).to eq("warning")
      end

      it "returns warning for American Indian outstanding with docs" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "American Indian Status")
        expect(helper.verification_type_class("American Indian Status", person)).to eq("warning")
      end

      it "returns warning for Citizenship outstanding with docs" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Citizenship")
        expect(helper.verification_type_class("Citizenship", person)).to eq("warning")
      end

      it "returns warning for Immigration status outstanding with docs" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Immigration status")
        expect(helper.verification_type_class("Immigration status", person)).to eq("warning")
      end
    end

    context "verification type status outstanding" do
      let(:lawful_presence_determination) { FactoryGirl.build(:lawful_presence_determination, aasm_state: "verification_outstanding") }
      before :each do
        person.consumer_role.is_state_resident = false
        person.consumer_role.vlp_documents = []
      end
      it "returns danger outstanding SSN" do
        expect(helper.verification_type_class("Social Security Number", person)).to eq("danger")
      end

      it "returns danger for outstanding Citizenship" do
        expect(helper.verification_type_class("Citizenship", person)).to eq("danger")
      end

      it "returns danger for outstanding Immigration status" do
        person.consumer_role.lawful_presence_determination = lawful_presence_determination
        expect(helper.verification_type_class("Immigration status", person)).to eq("danger")
      end
    end
  end

  describe '#ridp_type_class' do
    context 'ridp type status verified' do
      it 'returns success IDENTITY valid' do
        person.consumer_role.identity_validation = 'valid'
        expect(helper.ridp_type_class('Identity', person)).to eq('success')
      end

      it 'returns success APPLICATION verified' do
        person.consumer_role.application_validation = 'valid'
        expect(helper.ridp_type_class('Application', person)).to eq('success')
      end
    end

    context 'ridp type status in review' do
      it 'returns warning  for IDENTITY with docs' do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => 'Identity')
        expect(helper.ridp_type_class('Identity', person)).to eq('warning')
      end

      it 'returns warning  for APPLICATION with docs' do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => 'Application')
        expect(helper.ridp_type_class('Application', person)).to eq('warning')
      end
    end

    context 'ridp type status outstanding' do
      it 'returns danger outstanding IDENTITY' do
        person.consumer_role.ridp_documents = []
        person.consumer_role.identity_validation = 'outstanding'
        expect(helper.ridp_type_class('Identity', person)).to eq('danger')
      end

      it 'returns danger outstanding APPLICATION' do
        person.consumer_role.ridp_documents = []
        person.consumer_role.application_validation = 'outstanding'
        expect(helper.ridp_type_class('Application', person)).to eq('danger')
      end
    end
  end

  describe "#unverified?" do
    it "returns true if person is not fully verified" do
      expect(helper.unverified?(person)).to eq true
    end

    it "returns false if person consumer role status is fully verified" do
      person.consumer_role.aasm_state = "fully_verified"
      expect(helper.unverified?(person)).to be_falsey
    end
  end

  describe "#enrollment_group_unverified?" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

    before do
      allow_any_instance_of(Person).to receive_message_chain("primary_family").and_return(family)
      allow(family).to receive(:contingent_enrolled_active_family_members).and_return family.family_members
    end
    it "returns true if any family members has outstanding verification state" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.person.consumer_role.aasm_state="verification_outstanding"
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq true
    end

    it "returns false if all family members are fully verified or pending" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.save
      end
      expect(helper.enrollment_group_unverified?(person)).to eq false
    end
  end

  describe "#documents uploaded" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    it "returns true if any family member has uploaded docs" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
      end
      allow_any_instance_of(Person).to receive_message_chain("primary_family.active_family_members").and_return(family.family_members)
      expect(helper.documents_uploaded).to be_falsey
    end
  end

  describe "#documents count" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }

    it "returns the number of uploaded documents" do
      family.family_members.first.person.consumer_role.vlp_documents<<FactoryGirl.build(:vlp_document)
      expect(helper.documents_count(family)).to eq 2
    end
    it "returns 0 for consumer without vlp" do
      family.family_members.first.person.consumer_role.vlp_documents = []
      expect(helper.documents_count(family)).to eq 0
    end
  end

  describe "#hbx_enrollment_incomplete" do
    let(:hbx_enrollment_incomplete) { HbxEnrollment.new(:review_status => "incomplete") }
    let(:hbx_enrollment) { HbxEnrollment.new(:review_status => "ready") }
    context "if verification needed" do
      before :each do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.any?").and_return(true)
      end
      it "returns true if enrollment has complete review status" do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.first").and_return(hbx_enrollment_incomplete)
        expect(helper.hbx_enrollment_incomplete).to be_truthy
      end
      it "returns false for not incomplete status" do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.first").and_return(hbx_enrollment)
        expect(helper.hbx_enrollment_incomplete).to be_falsey
      end
    end

    context "without enrollments that needs verification" do
      before :each do
        allow_any_instance_of(Person).to receive_message_chain("primary_family.active_household.hbx_enrollments.verification_needed.any?").and_return(false)
      end

      it "returns false without enrollments" do
        expect(helper.hbx_enrollment_incomplete).to be_falsey
      end
    end
  end

  describe "#show_docs_status" do
    states_to_show = ["verified", "rejected"]
    states_to_hide = ["not submitted", "downloaded", "any"]

    states_to_show.each do |doc_state|
      it "returns true if document status is #{doc_state}" do
        expect(helper.show_doc_status(doc_state)).to eq true
      end
    end

    states_to_hide.each do |doc_state|
      it "returns true if document status is #{doc_state}" do
        expect(helper.show_doc_status(doc_state)).to eq false
      end
    end
  end

  describe '#review button class' do
    let(:obj) { double }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    before :each do
      family.active_household.hbx_enrollments << HbxEnrollment.new(:aasm_state => "enrolled_contingent")
      allow(obj).to receive_message_chain("family.active_household.hbx_enrollments.verification_needed.any?").and_return(true)
    end

    it 'returns default when the status is verified' do
       allow(helper).to receive(:get_person_v_type_status).and_return(['outstanding'])
       expect(helper.review_button_class(family)).to eq('default')
    end

    it 'returns info when the status is in review and outstanding' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['in review', 'outstanding'])
      expect(helper.review_button_class(family)).to eq('info')
    end

    it 'returns success when the status is in review ' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['in review'])
      expect(helper.review_button_class(family)).to eq('success')
    end

    it 'returns sucsess when the status is verified and in review but no outstanding' do
      allow(helper).to receive(:get_person_v_type_status).and_return(['in review', 'verified'])
      expect(helper.review_button_class(family)).to eq('success')
    end
  end

  describe '#get_person_v_types' do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    it 'returns verification types of the person' do
      status = 'verified'
      allow(helper).to receive(:verification_type_status).and_return(status)
      persons = family.family_members.map(&:person)

      expect(helper.get_person_v_type_status(persons)).to eq([status])
    end
  end

  describe "#show_v_type" do
    context "SSN" do
      it "returns in review if documents for ssn uploaded" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Social Security Number")
        expect(helper.show_v_type('Social Security Number', person)).to eq("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
      end
      it "returns verified if ssn_validation is valid" do
        person.consumer_role.ssn_validation = "valid"
        expect(helper.show_v_type('Social Security Number', person)).to eq("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end
      it "returns outstanding for unverified without documents and more than 24hs request" do
        expect(helper.show_v_type('Social Security Number', person)).to eq("Outstanding")
      end
      it "returns processing if consumer has pending state and no response from hub less than 24hours" do
        allow_any_instance_of(ConsumerRole).to receive(:processing_hub_24h?).and_return true
        expect(helper.show_v_type('Social Security Number', person)).to eq("&nbsp;&nbsp;Processing&nbsp;&nbsp;")
      end
    end
    context "Citizenship" do
      it "returns in review if documents for citizenship uploaded" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "citizenship")
        expect(helper.show_v_type('Citizenship', person)).to eq("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
      end
      it "returns verified if lawful_presence_determination successful" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(helper.show_v_type('Citizenship', person)).to eq("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end
      it "returns outstanding for unverified citizenship and more than 24hs request" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
        person.consumer_role.vlp_documents = []
        expect(helper.show_v_type('Citizenship', person)).to eq("Outstanding")
      end
      it "returns processing if consumer has pending state and no response from hub less than 24hours" do
        allow_any_instance_of(ConsumerRole).to receive(:processing_hub_24h?).and_return true
        person.consumer_role.vlp_documents = []
        expect(helper.show_v_type('Citizenship', person)).to eq("&nbsp;&nbsp;Processing&nbsp;&nbsp;")
      end
    end
    context "Immigration status" do
      it "returns in review if documents for citizenship uploaded" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Immigration status")
        expect(helper.show_v_type('Immigration status', person)).to eq("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
      end
      it "returns verified if lawful_presence_determination successful" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(helper.show_v_type('Immigration status', person)).to eq("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end
      it "returns outstanding for unverified citizenship and more than 24hs request" do
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
        person.consumer_role.vlp_documents = []
        expect(helper.show_v_type('Immigration status', person)).to eq("Outstanding")
      end
      it "returns processing if consumer has pending state and no response from hub less than 24hours" do
        allow_any_instance_of(ConsumerRole).to receive(:processing_hub_24h?).and_return true
        person.consumer_role.vlp_documents = []
        expect(helper.show_v_type('Immigration status', person)).to eq("&nbsp;&nbsp;Processing&nbsp;&nbsp;")
      end
    end
  end

  describe '#show_ridp_type' do
    context 'IDENTITY' do
      it 'returns in review if documents for identity uploaded' do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => 'Identity')
        expect(helper.show_ridp_type('Identity', person)).to eq("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
      end

      it 'returns verified if identity_validation is valid' do
        person.consumer_role.identity_validation = 'valid'
        expect(helper.show_ridp_type('Identity', person)).to eq("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end

      it 'returns outstanding if identity_validation is outstanding' do
        person.consumer_role.ridp_documents = []
        person.consumer_role.identity_validation = 'outstanding'
        expect(helper.show_ridp_type('Identity', person)).to eq("&nbsp;&nbsp;Outstanding&nbsp;&nbsp;")
      end
    end

    context 'APPLICATION' do
      it 'returns in review if documents for applicationuploaded' do
        person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => 'Application')
        expect(helper.show_ridp_type('Application', person)).to eq("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
      end

      it 'returns verified if identity_validation is valid' do
        person.consumer_role.application_validation = 'valid'
        expect(helper.show_ridp_type('Application', person)).to eq("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end

      it 'returns outstanding if identity_validation is outstanding' do
        person.consumer_role.application_validation = 'outstanding'
        expect(helper.show_ridp_type('Application', person)).to eq("&nbsp;&nbsp;Outstanding&nbsp;&nbsp;")
      end
    end
  end

  describe "#documents_list" do
    shared_examples_for "documents uploaded for one verification type" do |v_type, docs, result|
      context "#{v_type}" do
        before do
          person.consumer_role.vlp_documents=[]
          docs.to_i.times { person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => v_type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    shared_examples_for "documents uploaded for multiple verification types" do |v_type, result|
      context "#{v_type}" do
        before do
          person.consumer_role.vlp_documents=[]
          Person::VERIFICATION_TYPES.each {|type| person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    it_behaves_like "documents uploaded for one verification type", "Social Security Number", 1, 1
    it_behaves_like "documents uploaded for one verification type", "Citizenship", 1, 1
    it_behaves_like "documents uploaded for one verification type", "Immigration status", 1, 1
    it_behaves_like "documents uploaded for one verification type", "American Indian Status", 1, 1
  end

  describe "#ridp_documents_list" do
    shared_examples_for "ridp documents uploaded for one verification type" do |v_type, docs, result|
      context "#{v_type}" do
        before do
          person.consumer_role.ridp_documents=[]
          docs.to_i.times { person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => v_type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.ridp_documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    shared_examples_for "ridp documents uploaded for multiple verification types" do |v_type, result|
      context "#{v_type}" do
        before do
          person.consumer_role.ridp_documents=[]
          ['Identity', 'Application'].each {|type| person.consumer_role.ridp_documents << FactoryGirl.build(:ridp_document, :ridp_verification_type => type)}
        end
        it "returns array with #{result} documents" do
          expect(helper.ridp_documents_list(person, v_type).size).to eq result.to_i
        end
      end
    end
    it_behaves_like "ridp documents uploaded for one verification type", "Identity", 1, 1
    it_behaves_like "ridp documents uploaded for one verification type", "Application", 1, 1
  end

  describe "#build_admin_actions_list" do
    shared_examples_for "admin actions dropdown list" do |type, status, actions|
      before do
        allow(helper).to receive(:verification_type_status).and_return status
      end
      it "returns admin actions array" do
        expect(helper.build_admin_actions_list(person, type)).to eq actions
      end
    end

    it_behaves_like "admin actions dropdown list", "Citizenship", "outstanding", ["Verify", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "verified", ["Verify", "Reject", "View History", "Call HUB", "Extend"]
    it_behaves_like "admin actions dropdown list", "Citizenship", "in review", ["Verify", "Reject", "View History", "Call HUB", "Extend"]
  end

  describe "#build_ridp_admin_actions_list" do
    shared_examples_for "ridp admin actions dropdown list" do |type, status, actions|
      before do
        allow(helper).to receive(:ridp_type_status).and_return status
      end
      it "returns ridp admin actions array" do
        expect(helper.build_ridp_admin_actions_list(type, person)).to eq actions
      end
    end

    it_behaves_like "ridp admin actions dropdown list", "Identity", "outstanding", ["Verify"]
    it_behaves_like "ridp admin actions dropdown list", "Identity", "verified", ["Verify", "Reject"]
    it_behaves_like "ridp admin actions dropdown list", "Identity", "in review", ["Verify", "Reject"]
  end
end
