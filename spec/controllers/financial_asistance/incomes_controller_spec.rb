require 'rails_helper'

RSpec.describe FinancialAssistance::IncomesController, type: :controller do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :person => person, oim_id: "mahesh.")}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let!(:plan) { FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01") }
  let!(:hbx_profile) {FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period)}
  let!(:application) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryGirl.create(:applicant, application: application,family_member_id: family.primary_applicant.id) }
  let!(:income) {FactoryGirl.create(:financial_assistance_income, applicant: applicant)}
  let!(:valid_job_income_params){ {"kind"=>"wages_and_salaries", "employer_name"=>"sfd", "amount"=>"50001", "frequency_kind"=>"quarterly", "start_on"=>"11/08/2017", "end_on"=>"11/08/2018", "employer_address"=>{"kind"=>"work", "address_1"=>"2nd Main St", "address_2"=>"sfdsf", "city"=>"Washington", "state"=>"DC", "zip"=>"35467"}, "employer_phone"=>{"kind"=>"work", "full_phone_number"=>"(301)-848-8053"}} }
  let!(:valid_self_employed_income_params){ {"kind"=>"net_self_employment", "amount"=>"23", "frequency_kind"=>"monthly", "start_on"=>"11/01/2017", "end_on"=>"11/23/2017"} }
  let!(:valid_other_income_params){ {"kind"=>"alimony_and_maintenance", "amount"=>"45", "frequency_kind"=>"biweekly", "start_on"=>"11/01/2017", "end_on"=>"11/30/2017"}}
  let!(:valid_income_params){ {"kind"=>"capital_gains", "amount"=>"34.8", "frequency_kind"=>"monthly", "start_on"=>"09/04/2017", "end_on"=>"09/24/2017", "employer_name"=>""} }
  let!(:invalid_income_params){  {"kind"=>"ppp", "amount"=>"45.3", "frequency_kind"=>"monthly", "start_on"=>"09/04/2017", "end_on"=>"09/24/2017", "employer_name"=>""} }
  let(:income_employer_address_params){ {"address_1"=>"23 main st", "address_2"=>"", "city"=>"washington", "state"=>"dc", "zip"=>"12343"}}
  let(:income_employer_phone_params) {{"full_phone_number"=>""}}

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
      expect(response).to render_template(:financial_assistance)
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

    context "when params has application key" do
      it "When model is saved" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: income.id, income: valid_income_params, employer_phone: income_employer_phone_params
        expect(applicant.save).to eq true
      end

      it "should redirect to find_applicant_path when passing params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: income.id,income: valid_income_params, employer_address: income_employer_address_params, employer_phone: income_employer_phone_params, commit: "CONTINUE", last_step: true
        expect(response.headers['Location']).to have_content 'incomes'
        expect(response.status).to eq 302
        expect(flash[:notice]).to match('Income Added')
        expect(response).to redirect_to(financial_assistance_application_applicant_incomes_path(application, applicant))
      end

      it "should not redirect to find_applicant_path when not passing params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: income.id,income: valid_income_params, employer_address: income_employer_address_params, employer_phone: income_employer_phone_params, commit: "CONTINUE"
        expect(response.status).to eq 200
        expect(response).to render_template 'workflow/step'
      end

      it "should render workflow/step when we are not params last step" do
        post :step, application_id: application.id , applicant_id: applicant.id, id: income.id,income: valid_income_params, employer_address: income_employer_address_params, employer_phone: income_employer_phone_params, commit: "CONTINUE"
        expect(response).to render_template 'workflow/step'
      end
    end

    it "should render step if model is not saved" do
      post :step, application_id: application.id , applicant_id: applicant.id, id: income.id, income: invalid_income_params, employer_address: income_employer_address_params, employer_phone: income_employer_phone_params
      expect(response).to render_template 'workflow/step'
    end
  end

  context "create job income" do
    it "should create a job income  instance" do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_job_income_params, format: :js
      expect(applicant.incomes.count).to eq 1
    end
    it "should able to save an job income instance with the 'to' field blank " do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_job_income_params, format: :js
      valid_job_income_params["end_on"] = nil
      expect(applicant.incomes.count).to eq 1
    end
  end

  context "create self employed income" do
    it "should create a self employed income  instance" do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_self_employed_income_params, format: :js
      expect(applicant.incomes.count).to eq 1
    end
    it "should able to save an self employed income instance with the 'to' field blank " do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_self_employed_income_params, format: :js
      valid_self_employed_income_params["end_on"] = nil
      expect(applicant.incomes.count).to eq 1
    end
  end

  context "create other income" do
    it "should create a other income  instance" do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_other_income_params, format: :js
      expect(applicant.incomes.count).to eq 1
    end
    it "should able to save an other income instance with the 'to' field blank " do
      post :create, application_id: application.id , applicant_id: applicant.id, financial_assistance_benefit: valid_other_income_params, format: :js
      valid_other_income_params["end_on"] = nil
      expect(applicant.incomes.count).to eq 1
    end
  end

  context "destroy" do
    it "should create new income" do
      expect(applicant.incomes.count).to eq 1
      delete :destroy, application_id: application.id , applicant_id: applicant.id, id: income.id
      applicant.reload
      expect(applicant.incomes.count).to eq 0
    end
  end
end
