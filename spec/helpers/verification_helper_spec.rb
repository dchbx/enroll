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
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :authority => "hbx" })}
    context "Social Security Number" do
      it "returns outstanding status for consumer without state residency" do
        expect(helper.verification_type_status("Social Security Number", person)).to eq "outstanding"
      end

      it "returns in review for outstanding with docs" do
        person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Social Security Number")
        expect(helper.verification_type_status("Social Security Number", person)).to eq "in review"
      end

      it "returns verified status for consumer with state residency" do
        person.consumer_role.ssn_validation = "valid"
        expect(helper.verification_type_status("Social Security Number", person)).to eq "verified"
      end
    end

    context "Native American status" do
      context "native american with uploaded docs" do
        it "returns in review status" do
          person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "American Indian Status")
          expect(helper.verification_type_status("American Indian Status", person)).to eq "in review"
        end
      end
      context "native validation pending" do
        it "returns outstanding status" do
          person.consumer_role.native_validation = "pending"
          person.consumer_role.vlp_documents=[]
          expect(helper.verification_type_status("American Indian Status", person)).to eq "outstanding"
        end
      end
      context "native validation outstanding" do
        it "returns outstanding status" do
          person.consumer_role.native_validation = "outstanding"
          person.consumer_role.vlp_documents=[]
          expect(helper.verification_type_status("American Indian Status", person)).to eq "outstanding"
        end
      end
    end

    context "Citizenship/Immigration" do
      context "lawful presence valid" do
        it "returns verified status" do
          person.consumer_role.lawful_presence_determination.authorize!(verification_attr)
          expect(helper.verification_type_status("Immigration status", person)).to eq "verified"
        end
      end
      describe "Citizenship" do
        context "lawful presence with uploaded docs" do
          it "returns in review status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
            person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Citizenship")
            expect(helper.verification_type_status("Citizenship", person)).to eq "in review"
          end
        end
        context "lawful presence determination pending" do
          it "returns outstanding status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
            person.consumer_role.vlp_documents=[]
            expect(helper.verification_type_status("Citizenship", person)).to eq "outstanding"
          end
        end
        context "lawful presence determination outstanding" do
          it "returns outstanding status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
            person.consumer_role.vlp_documents=[]
            expect(helper.verification_type_status("Citizenship", person)).to eq "outstanding"
          end
        end
      end
      describe "Immigration status" do
        context "lawful presence with uploaded docs" do
          it "returns in review status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
            person.consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :verification_type => "Immigration status")
            expect(helper.verification_type_status("Immigration status", person)).to eq "in review"
          end
        end
        context "lawful presence determination pending" do
          it "returns outstanding status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
            person.consumer_role.vlp_documents=[]
            expect(helper.verification_type_status("Immigration status", person)).to eq "outstanding"
          end
        end
        context "lawful presence determination outstanding" do
          it "returns outstanding status" do
            person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
            person.consumer_role.vlp_documents=[]
            expect(helper.verification_type_status("Immigration status", person)).to eq "outstanding"
          end
        end
      end
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

  describe "#unverified?" do
    it "returns true if person is not fully verified" do
      expect(helper.unverified?(person)).to eq true
    end

    it "returns false if person consumer role status is fully verified" do
      person.consumer_role.aasm_state = "fully_verified"
      expect(helper.unverified?(person)).to be_falsey
    end
  end

  describe "#enrollment_group_verified?" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    it "returns true if any family members has outstanding verification state" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.person.consumer_role.aasm_state="verification_outstanding"
        member.save
      end
      allow_any_instance_of(Person).to receive_message_chain("primary_family.active_family_members").and_return(family.family_members)
      expect(helper.enrollment_group_unverified?(person)).to eq true
    end

    it "returns false if all family members are fully verified or pending" do
      family.family_members.each do |member|
        member.person = FactoryGirl.create(:person, :with_consumer_role)
        member.save
      end
      allow_any_instance_of(Person).to receive_message_chain("primary_family.active_family_members").and_return(family.family_members)
      expect(helper.enrollment_group_unverified?(person)).to eq false
    end
  end

  describe "#verification due date" do
    let(:family) { FactoryGirl.build(:family) }
    let(:hbx_enrollment_sp) { HbxEnrollment.new(:submitted_at => TimeKeeper.date_of_record, :special_verification_period => Date.new(2016,5,6)) }
    let(:hbx_enrollment_no_sp) { HbxEnrollment.new(:submitted_at => TimeKeeper.date_of_record) }
    before :each do
      assign(:family, family)
    end
    context "for special verification period" do
      it "returns special verification period" do
        allow(family).to receive_message_chain("active_household.hbx_enrollments.verification_needed").and_return([hbx_enrollment_sp])
        expect(helper.verification_due_date(family)).to eq Date.new(2016,5,6)
      end
    end

    context "with no special verification period" do
      it "calls determine due date method" do
        allow(family).to receive_message_chain("active_household.hbx_enrollments.verification_needed").and_return([hbx_enrollment_no_sp])
        expect((helper.verification_due_date(family))).to eq TimeKeeper.date_of_record + 95.days
      end
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
    it "returns the number of uploaded documents" do
      person.consumer_role.vlp_documents<<FactoryGirl.build(:vlp_document)
      expect(helper.documents_count(person)).to eq 2
    end
    it "returns 0 for consumer without vlp" do
      person.consumer_role.vlp_documents = []
      expect(helper.documents_count(person)).to eq 0
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
end