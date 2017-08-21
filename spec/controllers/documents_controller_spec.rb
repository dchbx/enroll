require 'rails_helper'

RSpec.describe DocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:consumer_role) {FactoryGirl.build(:consumer_role)}
  let(:document) {FactoryGirl.build(:vlp_document)}
  let(:family)  {FactoryGirl.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) { FactoryGirl.build(:hbx_enrollment) }

  before :each do
    sign_in user
  end

  describe "destroy" do
    before :each do
      person.consumer_role.vlp_documents = [document]
      delete :destroy, person_id: person.id, id: document.id
    end
    it "redirects_to verification page" do
      expect(response).to redirect_to verification_insured_families_path
    end

    it "should delete document record" do
      person.reload
      expect(person.consumer_role.vlp_documents).to be_empty
    end
  end

  describe "PUT update" do
    context "rejecting with comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :person=>{ :vlp_document=>{:comment=>"hghghg"}}, :comment => true, :status => "ready"
        document.reload
        expect(document.status).to eq("ready")
      end
    end

    context "accepting without comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :status => "accept"
        document.reload
        expect(document.status).to eq("accept")
      end
    end
  end
  describe "PUT extend due date" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      put :extend_due_date, family_member_id: family.primary_applicant.id, verification_type: "Citizenship"
    end

    it "should redirect to back" do
      expect(response).to redirect_to :back
    end
  end
  describe "PUT update_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    shared_examples_for "update verification type" do |type, reason, admin_action, updated_attr, result|
      it "updates #{updated_attr} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: type,
                                          verification_reason: reason,
                                          admin_action: admin_action}
        person.reload
        if updated_attr == "lawful_presence_update_reason"
          expect(person.consumer_role.lawful_presence_update_reason["v_type"]).to eq(type)
          expect(person.consumer_role.lawful_presence_update_reason["update_reason"]).to eq(result)
        else
          expect(person.consumer_role.send(updated_attr)).to eq(result)
        end
      end
    end

    context "Social Security Number verification type" do
      it_behaves_like "update verification type", "Social Security Number", "E-Verified in Curam", "verify", "ssn_validation", "valid"
      it_behaves_like "update verification type", "Social Security Number", "E-Verified in Curam", "verify", "ssn_update_reason", "E-Verified in Curam"
    end

    context "American Indian Status verification type" do
      before do
        person.consumer_role.update_attributes!(citizen_status: "indian_tribe_member")
      end
      it_behaves_like "update verification type", "American Indian Status", "Document in EnrollApp", "verify", "native_validation", "valid"
      it_behaves_like "update verification type", "American Indian Status", "Document in EnrollApp", "verify", "native_update_reason", "Document in EnrollApp"
    end

    context "Citizenship verification type" do
      it_behaves_like "update verification type", "Citizenship", "Document in EnrollApp", "verify", "lawful_presence_update_reason", "Document in EnrollApp"
    end

    context "Immigration verification type" do
      it_behaves_like "update verification type", "Immigration", "SAVE system", "verify", "lawful_presence_update_reason", "SAVE system"
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_verification_type, person_id: person.id
        expect(response).to redirect_to :back
      end
    end

    context "verification reason inputs" do
      it "should not update verification attributes without verification reason" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: "Citizenship",
                                          verification_reason: "",
                                          admin_action: "verify"}
        person.reload
        expect(person.consumer_role.lawful_presence_update_reason).to eq nil
      end

      VlpDocument::VERIFICATION_REASONS.each do |reason|
        it_behaves_like "update verification type", "Citizenship", reason, "verify", "lawful_presence_update_reason", reason
      end
    end
  end
end
