require 'rails_helper'
require File.join(Rails.root, "components/benefit_sponsors/spec/support/benefit_sponsors_product_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Employers::EmployerProfilesController, dbclean: :after_each do


  describe "GET index"  do

    let(:user) { double("user") }

    it 'should redirect' do
      sign_in(user)
      get :index
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

  end

  describe "GET new" do

    let(:user) { double("user") }

    it "should redirect" do
      sign_in(user)
      get :new
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end

  describe "GET show_profile" do

    let(:user) { double("user") }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should redirect" do
      sign_in(user)
      get :show_profile, params: {employer_profile_id: employer_profile}
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end

  describe "GET show" do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'
    let(:user) { double("user") }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    context "for new model employer profile match", dbclean: :after_each do

      before(:each) do
        abc_organization.update_attributes!(hbx_id: employer_profile.hbx_id)
      end

      it "should redirect" do
        sign_in(user)
        get :show, params: {id: employer_profile}
        expect(response).to redirect_to("/benefit_sponsors/profiles/employers/employer_profiles/#{abc_profile.id}?tab=home")
      end
    end

    context "for new model employer profile don't match", dbclean: :after_each do
      it "should redirect" do
        sign_in(user)
        get :show, params: {id: employer_profile}
        expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
      end
    end
  end

  describe "GET welcome", dbclean: :after_each do
    let(:user) { double("user") }

    it "should redirect" do
      sign_in(user)
      get :welcome
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

  end


  describe "GET search", dbclean: :after_each do
    let(:user) { double("user")}
    let(:person) { double("Person", agent?: false)}
    before(:each) do
      allow(user).to receive(:person).and_return(person)
      sign_in user
      get :search
    end

    it "renders the 'search' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns[:employer_profile]).to be_a(Forms::EmployerCandidate)
    end
  end


  describe "GET export_census_employees", dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { abc_profile }

    it "should export cvs" do
      sign_in(user)
      get :export_census_employees, params: {employer_profile_id: employer_profile}, format: :csv
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }
    it "should load upload Page" do
      sign_in(user)
      get :new_document, params: {id: employer_profile}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end


  describe "POST Upload Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }
    #let(:params) { { id: employer_profile.id, file:'test/JavaScript.pdf', subject: 'JavaScript.pdf' } }

    let(:subject){"Employee Attestation"}
    let(:file) { double }
    let(:temp_file) { double }
    let(:file_path) { Rails.root+'test/JavaScript.pdf' }

    before(:each) do
      @controller = Employers::EmployerProfilesController.new
      #allow(file).to receive(:original_filename).and_return("some-filename")
      allow(file).to receive(:tempfile).and_return(temp_file)
      allow(temp_file).to receive(:path)
      allow(@controller).to receive(:file_path).and_return(file_path)
      allow(@controller).to receive(:file_name).and_return("sample-filename")
      #allow(@controller).to receive(:file_content_type).and_return("application/pdf")
    end

    context "upload document", dbclean: :after_each do
      it "redirects to document list page" do
        sign_in user
        post :upload_document, params: {id: employer_profile.id, file: file, subject: subject}
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "Delete Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should delete documents" do
      sign_in(user)
      get :delete_documents, params: {id: employer_profile.id, ids:[1]}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end
end
