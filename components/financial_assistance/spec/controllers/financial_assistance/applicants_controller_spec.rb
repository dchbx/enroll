# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicantsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 40.years)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member,person: person) }
  let!(:plan) { FactoryBot.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01") }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period)}
  let!(:application) { FactoryBot.create(:application,family: family, aasm_state: "draft",effective_date: TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryBot.create(:applicant, application: application, is_claimed_as_tax_dependent: false, is_self_attested_blind: false, has_daily_living_help: false,need_help_paying_bills: false, family_member_id: family.primary_applicant.id) }
  let(:financial_assistance_applicant_valid) do
    {
      "is_ssn_applied" => "false",
      "non_ssn_apply_reason" => "we",
      "is_pregnant" => "false",
      "pregnancy_due_on" => "",
      "children_expected_count" => "",
      "is_post_partum_period" => "false",
      "pregnancy_end_on" => "09/21/2017",
      "is_former_foster_care" => "false",
      "foster_care_us_state" => "",
      "age_left_foster_care" => "",
      "is_student" => "false",
      "student_kind" => "",
      "student_status_end_on" => "",
      "student_school_kind" => "",
      "is_self_attested_blind" => "false",
      "has_daily_living_help" => "false",
      "need_help_paying_bills" => "false"
    }
  end
  let(:financial_assistance_applicant_invalid) do
    {
      "is_required_to_file_taxes" => nil,
      "is_claimed_as_tax_dependent" => nil
    }
  end
  let(:applicant_params) do
    {
      "is_required_to_file_taxes" => true,
      "is_claimed_as_tax_dependent" => false,
      "has_job_income" => "false",
      "has_self_employment_income" => "false",
      "has_other_income" => "false",
      "has_deductions" => "false",
      "has_enrolled_health_coverage" => "false",
      "has_eligible_health_coverage" => "false"
    }
  end

  before do
    sign_in(user)
  end

  context "GET other questions" do
    it "should assign applications", dbclean: :after_each do
      get :other_questions, params: { application_id: application.id, id: applicant.id }
      expect(assigns(:applicant).id).to eq applicant.id
      expect(response).to render_template(:financial_assistance_nav)
    end
  end

  context "GET save questions" do
    it "should save questions and redirects to edit_financial_assistance_application_path", dbclean: :after_each do
      get :save_questions, params: { application_id: application.id, id: applicant.id, financial_assistance_applicant: financial_assistance_applicant_valid }
      expect(response).to have_http_status(302)
      expect(response.headers['Location']).to have_content 'edit'
      expect(response).to redirect_to(edit_application_path(application))
    end
    # TODO: This is run under the save context of :other_qns which runs the method presence_of_attr_other_qns and does not validate the is_required_to_file_taxes or
    # is_claimed_as_tax_dependent, which are passed as nil here as "invalid params."
    # Should they be added to the presence_of_attr_other_qns method?
    xit "should not save and redirects to other_questions_financial_assistance_application_applicant_path", dbclean: :after_each do
      get :save_questions, params: { application_id: application.id, id: applicant.id, financial_assistance_applicant: financial_assistance_applicant_invalid }
      expect(response).to have_http_status(302)
      expect(response.headers['Location']).to have_content 'other_questions'
      expect(response).to redirect_to(other_questions_application_applicant_path(application, applicant))
    end
  end

  context "POST step" do
    before do
      controller.instance_variable_set(:@modal, application)
    end

    it "should render step if no key present in params with modal_name" do
      post :step, params: { application_id: application.id, id: applicant.id }
      expect(response).to render_template 'workflow/step'
    end

    context "when params has application key" do
      it "When model is saved" do
        post :step, params: { application_id: application.id, id: applicant.id, applicant: financial_assistance_applicant_valid }
        expect(applicant.save).to eq true
      end

      it "should redirect to income index when in last step (tax_info)" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: applicant_params, last_step: true }
        expect(response.headers['Location']).to have_content 'incomes'
        expect(response.status).to eq 302
        expect(response).to redirect_to(application_applicant_incomes_path(application, applicant))
      end

      it "should not redirect to find_applicant_path when not passing params last step" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: applicant_params }
        expect(response.status).to eq 200
        expect(response).to render_template 'workflow/step'
      end

      it "should render_template 'workflow/step' when params are invalid" do
        post :step, params: { application_id: application.id, id: applicant.id, commit: "CONTINUE", applicant: financial_assistance_applicant_invalid}
        expect(response).to render_template 'workflow/step'
      end
    end

    it "should render step if model is not saved" do
      post :step, params: { application_id: application.id, id: applicant.id }
      expect(response).to render_template 'workflow/step'
    end
  end

  context "GET age of applicant" do
    it "should return age of applicant", dbclean: :after_each do
      get :age_of_applicant, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response.body).to eq person.age_on(TimeKeeper.date_of_record).to_s
    end
  end

  context "GET primary_applicant_has_spouse" do
    it "should check for primary_applicant_has_spouse", dbclean: :after_each do
      get :primary_applicant_has_spouse, params: { application_id: application.id, applicant_id: applicant.id }
      expect(response.body).to eq "false"
    end
  end
end
