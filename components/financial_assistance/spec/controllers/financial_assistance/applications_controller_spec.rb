# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}


  describe "GET index" do

    before(:each) do
      sign_in user
    end

    it "assigns @applications" do
      application = FinancialAssistance::Application.create!(family_id: family_id)
      get :index
      expect(assigns(:applications).to_a).to eq([application])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end
  end

  context "copy an application" do
    let(:family1_id) { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family1_id, aasm_state: 'determined' }

    before(:each) do
      sign_in user
      get :copy, params: { :id => application.id }
      @new_application = FinancialAssistance::Application.where(family_id: application.family_id, :id.ne => application.id).first
    end

    it "redirects to the new application copy" do
      expect(response).to redirect_to(edit_application_path(assigns(:application).reload))
    end

    it 'create duplicate application' do
      expect(@new_application.family_id).to eq application.family_id
    end

    it 'copies all the applicants' do
      expect(@new_application.applicants.count).to eq application.applicants.count
    end
  end
end

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}
  let(:family_member_id) { family.primary_applicant.id }
  let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant, application: application,
                                  is_claimed_as_tax_dependent: false,
                                  is_self_attested_blind: false,
                                  has_daily_living_help: false,
                                  need_help_paying_bills: false,
                                  is_primary_applicant: true,
                                  family_member_id: family_member_id)
  end
  let!(:application2) { FactoryBot.create(:application, family_id: family_id, aasm_state: "draft", effective_date: TimeKeeper.date_of_record) }
  let!(:applicant2) { FactoryBot.create(:applicant, application: application2, family_member_id: family_member_id) }
  let(:application_valid_params) { {"medicaid_terms" => "yes", "report_change_terms" => "yes", "medicaid_insurance_collection_terms" => "yes", "parent_living_out_of_home_terms" => "true", "attestation_terms" => "yes", "submission_terms" => "yes"} }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period)}

  before do
    allow(person).to receive(:financial_assistance_identifier).and_return(family_id)
    sign_in(user)
  end

  context "GET Index" do
    it "should assign applications", dbclean: :after_each do
      get :index
      applications = FinancialAssistance::Application.where(family_id: family_id)
      expect(assigns(:applications)).to eq applications
    end
  end

  context "GET new" do
    it "should assign application" do
      get :new
      expect(assigns(:application).class).to eq FinancialAssistance::Application
    end
  end

  context "GET edit" do
    it "should render" do
      get :edit, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "POST step" do
    before do
      controller.instance_variable_set(:@modal, application)
    end

    it "should render step if no key present in params with modal_name" do
      post :step, params: { id: application.id }
      expect(response).to render_template 'workflow/step'
    end

    context "when params has application key" do
      let(:success_result) { double(success?: true)}
      it "When model is saved" do
        post :step, params: { id: application.id, application: application_valid_params }
        expect(application.save).to eq true
      end

      it "should fail during publish application and redirects to error_page" do
        post :step, params: { id: application2.id, commit: "Submit Application", application: application_valid_params }
        expect(response).to redirect_to(application_publish_error_application_path(application2))
      end

      it "should successfully publish application and redirects to wait_for_eligibility" do
        allow(application).to receive(:complete?).and_return(true)
        allow(application).to receive(:submit!).and_return(true)
        allow(FinancialAssistance::Operations::Application::RequestDetermination).to receive_message_chain(:new, :call).and_return(success_result)
        allow(FinancialAssistance::Application).to receive(:find_by).and_return(application)
        post :step, params: { id: application.id, commit: "Submit Application", application: application_valid_params }
        expect(response).to redirect_to(wait_for_eligibility_response_application_path(application))
      end
    end

    it "should render step if model is not saved" do
      post :step, params: { id: application.id }
      expect(response).to render_template 'workflow/step'
    end
  end

  context "GET copy" do
    context "when there is not response from eligibility service" do

      before do
        FinancialAssistance::Application.where(family_id: family_id).each {|app| app.update_attributes(aasm_state: "determined")}
      end

      it 'should copy applicant and redirect to financial assistance application edit path' do
        get :copy, params: { id: application.id }
        existing_app_ids = [application.id, application2.id]
        copy_app = FinancialAssistance::Application.where(family_id: family_id).reject {|app| existing_app_ids.include? app.id}.first
        expect(response).to redirect_to(edit_application_path(copy_app.id))
      end
    end

    context "when there is response from eligibility service" do
      include FinancialAssistance::L10nHelper
      include ActionView::Helpers::TranslationHelper

      before do
        allow(controller).to receive(:call_service)
        controller.instance_variable_set(:@assistance_status, false)
        controller.instance_variable_set(:@message, "101")
        get :copy, params: { id: application.id }
      end

      let(:message) {l10n("faa.acdes_lookup")}

      it 'should not copy applicant and redirect to financial_assistance_applications_path' do
        expect(response).to redirect_to(applications_path)
      end

      it 'should not copy applicant and throw message' do
        expect(flash[:error].to_s).to match(message)
      end
    end
  end

  context "uqhp_flow" do
    it "should redirect to insured family members" do
      get :uqhp_flow
      expect(FinancialAssistance::Application.where(family_id: family_id, aasm_state: "draft").count).to eq 0
      expect(response).to redirect_to(main_app.insured_family_members_path(consumer_role_id: person.consumer_role.id))
    end
  end

  context "GET review_and_submit" do
    it 'should review and submit page' do
      application.update_attributes(:aasm_state => "draft")
      get :review_and_submit, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(assigns(:application).aasm_state).to eq("draft")
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "GET review" do
    it "should be successful" do
      application.update_attributes(:aasm_state => "submitted")
      get :review, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end

    it "should redirect to applications page" do
      get :review, params: { id: FinancialAssistance::Application.new.id }
      expect(response).to redirect_to(applications_path)
    end
  end

  context "GET wait_for_eligibility_response" do
    it "should redirect to eligibility_response_error if doesn't find the ED on wait_for_eligibility_response page" do
      get :wait_for_eligibility_response, params: { id: application.id }
      expect(assigns(:application)).to eq application
    end
  end

  context "GET eligibility_results" do
    it 'should get eligibility results' do
      get :eligibility_results, params: {:id => application.id, :cur => 1}
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "GET application_publish_error" do
    it 'should get application publish error' do
      get :application_publish_error, params: { id: application.id }
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "check eligibility results received" do
    it "should return true if the Header of the response doesn't has the success status code" do
      get :check_eligibility_results_received, params: { id: application.id }
      expect(response.body).to eq "false"
    end

    it 'should return true if the Header of the response has the success status code' do
      application.update_attributes(determination_http_status_code: 200)
      get :check_eligibility_results_received, params: { id: application.id }
      expect(response.body).to eq "true"
    end
  end
end
