# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::BenefitsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let(:family_id) { BSON::ObjectId.new }
  let(:family_member_id) { BSON::ObjectId.new }
  # let!(:family) { FactoryBot.create(:family, :with_primary_family_member,person: person) }
  let!(:application) { FactoryBot.create(:application, family_id: family_id, aasm_state: 'draft',effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryBot.create(:applicant, application: application,family_member_id: family_member_id) }
  let!(:benefit) {FactoryBot.create(:financial_assistance_benefit, applicant: applicant)}
  let!(:valid_params1) do
    {
      'kind' => 'is_eligible',
      'start_on' => '09/04/2017',
      'end_on' => '09/20/2017',
      'insurance_kind' => 'child_health_insurance_plan',
      'esi_covered' => 'self',
      'employer_name' => '',
      'employer_id' => '',
      'employee_cost' => '',
      'employee_cost_frequency' => ''
    }
  end
  let!(:invalid_params) do
    {
      'kind' => 'pp',
      'start_on' => '09/04/2017',
      'end_on' => '09/20/2017',
      'insurance_kind' => 'child_health_insurance_plan',
      'esi_covered' => 'self',
      'employer_name' => '',
      'employer_id' => '',
      'employee_cost' => '',
      'employee_cost_frequency' => ''
    }
  end
  let(:employer_address){ {'address_1' => '', 'address_2' => '', 'city' => '', 'state' => '', 'zip' => ''}}
  let(:employer_phone) {{'full_phone_number' => ''}}

  before do
    sign_in(user)
  end

  context 'GET index' do
    it 'should render template financial assistance' do
      get :index, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context 'POST new' do
    it 'should load template work flow steps' do
      post :new, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response).to render_template(:financial_assistance_nav)
      expect(response).to render_template 'workflow/step'
    end
  end

  context 'POST step' do
    before do
      controller.instance_variable_set(:@modal, application)
      controller.instance_variable_set(:@applicant, applicant)
    end

    it 'should show flash error message nil' do
      expect(flash[:error]).to match(nil)
    end

    it 'should render step if no key present in params with modal_name' do
      post :step, params: { application_id: application.id, applicant_id: applicant.id, benefit: {start_on: '09/04/2017', end_on: '09/20/2017'} }
      expect(response).to render_template 'financial_assistance/benefits/create'
    end

    context 'when params has application key' do
      it 'When model is saved' do
        post :step, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id, employer_address: employer_address, employer_phone: employer_phone }
        expect(applicant.save).to eq true
      end

      it 'should redirect to find_applicant_path when passing params last step' do
        post :step, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id,benefit: valid_params1, employer_address: employer_address, employer_phone: employer_phone, commit: 'CONTINUE', last_step: true }
        expect(response.headers['Location']).to have_content 'benefits'
        expect(response.status).to eq 302
        expect(flash[:notice]).to match('Benefit Info Added.')
        expect(response).to redirect_to(application_applicant_benefits_path(application, applicant))
      end

      it 'should not redirect to find_applicant_path when not passing params last step' do
        post :step, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id,benefit: valid_params1, employer_address: employer_address, employer_phone: employer_phone, commit: 'CONTINUE' }
        expect(response.status).to eq 200
        expect(response).to render_template 'workflow/step'
      end

      it 'should render workflow/step when we are not params last step' do
        post :step, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id,benefit: valid_params1, employer_address: employer_address, employer_phone: employer_phone, commit: 'CONTINUE' }
        expect(response).to render_template 'workflow/step'
      end
    end

    it 'should render step if model is not saved' do
      post :step, params: {application_id: application.id, applicant_id: applicant.id, id: benefit.id, benefit: invalid_params, employer_address: employer_address, employer_phone: employer_phone}
      expect(flash[:error]).to match('Pp Is Not A Valid Benefit Kind Type')
      expect(response).to render_template 'workflow/step'
    end
  end

  context "create" do
    it "should create a benefit instance" do
      post :create, params: { application_id: application.id, applicant_id: applicant.id, benefit: {start_on: "09/04/2017", end_on: "09/20/2017"}}, format: :js
      expect(applicant.benefits.count).to eq 1
    end
    it "should able to save an benefit instance with the 'to' field blank " do
      post :create, params: { application_id: application.id, applicant_id: applicant.id, benefit: {start_on: "09/04/2017", end_on: " "}}, format: :js
      expect(applicant.benefits.count).to eq 1
    end
  end

  context 'destroy' do
    it 'should delete a benefit instance' do
      expect(applicant.benefits.count).to eq 1
      delete :destroy, params: { application_id: application.id, applicant_id: applicant.id, id: benefit.id }
      applicant.reload
      expect(applicant.benefits.count).to eq 0
    end
  end
end
