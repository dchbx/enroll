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

  describe "PUT update individual" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    it "redirect_to back" do
      post :update_individual, person_id: person.id
      expect(response).to redirect_to :back
    end

    it "transfers the current state" do
      post :update_individual, person_id: person.id
      person.reload
      expect(person.consumer_role.aasm_state).to eq("fully_verified")
    end
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
      put :extend_due_date, family_id: family.id
    end

    it "should redirect to back" do
      expect(response).to redirect_to :back
    end
  end
  describe "PUT update_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    context "Social Security Number verification type" do
      it "should update attributes" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: "Social Security Number",
                                          verification_reason: "in Curam list"}
        person.reload
        expect(person.consumer_role.ssn_validation).to eq("valid")
        expect(person.consumer_role.ssn_update_reason).to eq("in Curam list")
      end
    end

    context "Citizenship verification type" do
      it "should update attributes" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: "Citizenship",
                                          verification_reason: "documents copy"}
        person.reload
        expect(person.consumer_role.lawful_presence_update_reason).to be_a Hash
        expect(person.consumer_role.lawful_presence_update_reason).to eq({"v_type"=>"Citizenship", "update_reason"=>"documents copy"})
      end
    end

    context "Immigration verification type" do
      it "should update attributes" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: "Immigration",
                                          verification_reason: "he is really good man, so why not )"}
        person.reload
        expect(person.consumer_role.lawful_presence_update_reason).to be_a Hash
        expect(person.consumer_role.lawful_presence_update_reason[:v_type]).to eq("Immigration")
        expect(person.consumer_role.lawful_presence_update_reason[:update_reason]).to eq("he is really good man, so why not )")
      end
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_verification_type, person_id: person.id
        expect(response).to redirect_to :back
        expect(flash[:notice]).to eq("Verification type successfully approved.")
      end

      it "should redirect to back" do
        allow_any_instance_of(DocumentsController).to receive(:all_types_verified?).and_return(true)
        post :update_verification_type, person_id: person.id
        expect(response).to redirect_to(update_individual_documents_path(:person_id => person.id))
        expect(flash[:notice]).to eq("Individual verification status was completely approved.")
      end
    end
  end
end
