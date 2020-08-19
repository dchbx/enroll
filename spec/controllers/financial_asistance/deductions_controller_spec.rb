require 'rails_helper'

RSpec.describe FinancialAssistance::DeductionsController, type: :controller do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :person => person, oim_id: "mahesh.")}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let!(:plan) { FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01") }
  let!(:hbx_profile) {FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period)}
  let!(:application) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryGirl.create(:applicant, application: application,family_member_id: family.primary_applicant.id) }
  let!(:deduction) {FactoryGirl.create(:financial_assistance_deduction, applicant: applicant)}
  let!(:valid_deductions_params) {
    {"kind"=>"alimony_paid", "amount"=>"23.5", "frequency_kind"=>"biweekly", "start_on"=>"09/09/2017", "end_on"=>"09/29/2017"}
  }
  let!(:deduction_valid_params) {
    {"kind"=>"alimony_paid", "amount"=>"23.5", "frequency_kind"=>"biweekly", "start_on"=>"09/09/2017", "end_on"=>"09/29/2017"}
  }
  let!(:deduction_invalid_params) {
    {"kind"=>"pppppp", "amount"=>"23.5", "frequency_kind"=>"biweekly", "start_on"=>"09/09/2017", "end_on"=>"09/29/2017"}
  }

  before do
    sign_in(user)
  end

  context "GET index" do
    it "should render template financial assistance" do
      get :index, application_id: application.id , applicant_id: applicant.id
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "POST new" do
    it "should load template work flow steps" do
      post :new, application_id: application.id , applicant_id: applicant.id
      expect(response).to render_template 'workflow/step'
    end
  end

  context "POST step" do
    before do
      controller.instance_variable_set(:@modal, application)
      controller.instance_variable_set(:@applicant, applicant)
    end

    it "should show flash error message nil" do
      expect(flash[:error]).to match(nil)
    end

    it "should render create if no key present in params with modal_name" do
      post :step, application_id: application.id , applicant_id: applicant.id
      expect(response).to render_template 'financial_assistance/deductions/create'
    end

    it "should render create if no key present in params with modal_name" do
      post :step, application_id: application.id , applicant_id: applicant.id, :financial_assistance_deduction => {:start_on=> "09/09/2017", :end_on=> "09/20/2017"}
      expect(response).to render_template 'financial_assistance/deductions/create'
    end

    context "when params has application key" do
      it "When model is saved" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: deduction.id, deduction: deduction_valid_params
        expect(applicant.save).to eq true
      end

      it "should redirect to find_applicant_path when passing params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: deduction.id, deduction: deduction_valid_params, commit: "CONTINUE", last_step: true
        expect(response.headers['Location']).to have_content 'deductions'
        expect(response.status).to eq 302
        expect(flash[:notice]).to match('Deduction Added')
        expect(response).to redirect_to(financial_assistance_application_applicant_deductions_path(application, applicant))
      end

      it "should not redirect to find_applicant_path when not passing params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: deduction.id, deduction: deduction_valid_params, commit: "CONTINUE"
        expect(response.status).to eq 200
      end

      it "should render workflow/step when we are not params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: deduction.id, deduction: deduction_valid_params, commit: "CONTINUE"
        expect(response).to render_template 'workflow/step'
      end
    end

    it "should render step if model is not saved" do
      post :step, application_id: application.id , applicant_id: applicant.id, id: deduction.id, deduction: deduction_invalid_params
      expect(flash[:error]).to match("Pppppp Is Not A Valid Deduction Type")
      expect(response).to render_template 'workflow/step'
    end
  end

  context "create deductions (income adjustments)" do
    it "should create a deductions (income adjustments)  instance" do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_deductions_params, format: :js
      expect(applicant.deductions.count).to eq 1
    end
    it "should be able to create a deductions (income adjustments)  instance with the 'to' field blank " do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_deductions_params, format: :js
      valid_deductions_params["end_on"] = nil
      expect(applicant.deductions.count).to eq 1
    end
  end

  context "destroy" do
    it "should create new deductions" do
      expect(applicant.deductions.count).to eq 1
      delete :destroy, application_id: application.id , applicant_id: applicant.id, id: deduction.id
      applicant.reload
      expect(applicant.deductions.count).to eq 0
    end
  end
end
