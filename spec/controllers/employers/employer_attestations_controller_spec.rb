require 'rails_helper'

RSpec.describe Employers::EmployerAttestationsController do


  describe "GET edit" do
    let(:user) { FactoryGirl.create(:user) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

    it "should render the edit template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      xhr :get, :edit, {id: employer_profile.id}
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new" do
    let(:user) { FactoryGirl.create(:user) }

    it "should render the edit template" do
      sign_in(user)
      xhr :get, :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST create" do
    let(:user) { FactoryGirl.create(:user) }
    let(:tempfile) { double(path: 'tmp/sample.pdf') }
    let(:file) { double(original_filename: 'sample.pdf', size: 400, tempfile: tempfile) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

    before do 
      allow(controller).to receive(:params).and_return({id: employer_profile.id, file: file})
      allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)

      sign_in(user)
      post :create, {id: employer_profile.id}
    end

    context 'when file upload failed' do
      let(:doc_uri) { nil } 

      it "should render the edit template" do
        expect(flash[:error]).to eq "Could not save the file in S3 storage"
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when file upload successful' do
      let(:doc_uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket" }

      it 'should return success' do
        expect(flash[:notice]).to eq "File Saved"
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PUT update" do 
    let(:user) { FactoryGirl.create(:user) }
    let(:attestation_doc) { FactoryGirl.create(:employer_attestation_document) }

    it "should render the edit template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(attestation_doc).to receive(:submit_review).and_return(true)

      sign_in(user)
      put :update, {id: attestation_doc.employer_profile.id, employer_attestation_id: attestation_doc.id, status: 'accepted'}

      expect(flash[:notice]).to eq "Employer attestation updated successfully"
      expect(response).to have_http_status(:redirect)
    end
  end
end
