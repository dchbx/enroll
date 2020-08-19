require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, type: :controller do
  let(:person) { FactoryGirl.create(:person)}
  let(:user) { FactoryGirl.create(:user, :person=>person); }

  describe "GET index" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

    before(:each) do
      sign_in user
      allow(person).to receive(:primary_family).and_return(family)
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    it "assigns @applications" do
      application = person.primary_family.applications.new
      application.populate_applicants_for(person.primary_family)
      application.save!
      get :index
      expect(assigns(:applications)).to eq([application])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end
  end

  context "copy an application" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:primary_member) {family.primary_applicant.person}
    let(:spouse) {FactoryGirl.create(:family_member, family: family).person}
    let(:child) {FactoryGirl.create(:family_member, family: family).person}
    let(:unrelated_member) {FactoryGirl.create(:family_member, family: family).person}
    let!(:hbx_profile) {FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period)}
    let!(:plan) { FactoryGirl.create(:plan, active_year: TimeKeeper.date_of_record.year, hios_id: "86052DC0400001-01") }
    let(:application) { FactoryGirl.create :application, family: family, aasm_state: 'determined' }

    before(:each) do
      sign_in user
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
      allow(application).to receive(:benchmark_plan).and_return plan
      spouse.add_relationship(primary_member, "spouse", family.id)
      primary_member.add_relationship(spouse, "spouse", family.id)
      child.add_relationship(primary_member, "child", family.id)
      primary_member.add_relationship(child, "parent", family.id)
      child.add_relationship(spouse, "child", family.id)
      spouse.add_relationship(child, "parent", family.id)
      unrelated_member.add_relationship(primary_member, "unrelated", family.id)
      primary_member.add_relationship(unrelated_member, "unrelated", family.id)
      family.build_relationship_matrix
      
      get :copy, :id => application.id
    end

    it "redirects to the new application copy" do
      expect(response).to redirect_to(edit_financial_assistance_application_path(assigns(:application).reload))
    end

    it "copies the application's primary application id" do
      draft_application = assigns(:application)
      original_primary_applicant = application.family.family_members.find_by(:is_primary_applicant => true)
      copied_primary_applicant = draft_application.family.family_members.find_by(:is_primary_applicant => true)
      expect(original_primary_applicant.id).to eq (copied_primary_applicant.id)
    end

    it "copies the application's primary_member - spouse relationship as spouse" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, spouse.id, family.id)).to eq "spouse"
    end

    it "copies the application's spouse - primary_member relationship as spouse" do
      expect(assigns(:application).family.find_existing_relationship(spouse.id, primary_member.id, family.id)).to eq "spouse"
    end

    it "copies the application's primary member - child relationship as parent" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, child.id, family.id)).to eq "parent"
    end

    it "copies the application's child - primary_member relationship as child" do
      expect(assigns(:application).family.find_existing_relationship(child.id, primary_member.id, family.id)).to eq "child"
    end

    it "copies the application's spouse - child relationship as parent" do
      expect(assigns(:application).family.find_existing_relationship(spouse.id, child.id, family.id)).to eq "parent"
    end

    it "copies the application's child - spouse relationship as child" do
      expect(assigns(:application).family.find_existing_relationship(child.id, spouse.id, family.id)).to eq "child"
    end

    it "copies the application's primary_member - unrelated_member relationship as unrelated" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, unrelated_member.id, family.id)).to eq "unrelated"
    end

    it "copies the application's unrelated_member - primary_member relationship as unrelated" do
      expect(assigns(:application).family.find_existing_relationship(unrelated_member.id, primary_member.id, family.id)).to eq "unrelated"
    end
  end
end

RSpec.describe FinancialAssistance::ApplicationsController, type: :controller do
  render_views
  let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :person => person, oim_id: "mahesh.")}
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let!(:plan) { FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01") }
  let!(:hbx_profile) {FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period)}
  let!(:application) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant) { FactoryGirl.create(:applicant, application: application, is_claimed_as_tax_dependent:false, is_self_attested_blind:false, has_daily_living_help:false,need_help_paying_bills:false, family_member_id: family.primary_applicant.id) }
  let!(:application2) { FactoryGirl.create(:application,family: family, aasm_state: "draft",effective_date:TimeKeeper.date_of_record) }
  let!(:applicant2) { FactoryGirl.create(:applicant, application: application2, family_member_id: family.primary_applicant.id) }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:application_valid_params) { {"medicaid_terms"=>"yes", "report_change_terms"=>"yes", "medicaid_insurance_collection_terms"=>"yes", "parent_living_out_of_home_terms"=>"true", "attestation_terms"=>"yes", "submission_terms"=>"yes"} }

  before do
    sign_in(user)
    #allow(application).to receive(:active_applicants).and_return [applicant]
    allow(application).to receive(:benchmark_plan).and_return plan
  end

  context "GET Index" do
    it "should assign applications", dbclean: :after_each do
      get :index
      expect(assigns(:family)).to eq person.primary_family
      expect(assigns(:applications)).to eq family.applications
    end
  end

  context "GET new" do
    it "should assign application" do
      get :new
      expect(assigns(:application).class).to eq FinancialAssistance::Application
    end
  end

  context "POST create" do
    it "should redirect" do
      post :create
      family.reload
      existing_app_ids = [application.id, application2.id]
      new_app = application.family.applications.reject{ |app| existing_app_ids.include? app.id }.first
      expect(response).to redirect_to(edit_financial_assistance_application_path(new_app.id))
    end
  end

  context "GET edit" do
    it "should render" do
      get :edit, id: application.id
      expect(assigns(:family)).to eq person.primary_family
      expect(assigns(:application)).to eq application
      expect(assigns(:missing_relationships)).to eq family.find_missing_relationships(family.build_relationship_matrix)
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "POST step" do
    before do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:benchmark_plan).and_return plan
      controller.instance_variable_set(:@modal, application)
    end

    it "should render step if no key present in params with modal_name" do
      post :step, id: application.id
      expect(response).to render_template 'workflow/step'
    end

    context "when params has application key" do
      it "When model is saved" do
        post :step, id: application.id, application: application_valid_params
        expect(application.save).to eq true
      end

      it "should fail during publish application and redirects to error_page" do
        post :step, id: application2.id, commit: "Submit Application", application: application_valid_params
        expect(response).to redirect_to(application_publish_error_financial_assistance_application_path(application2))
      end

      it "should successfully publish application and redirects to wait_for_eligibility" do
        post :step, id: application.id, commit: "Submit Application", application: application_valid_params
        expect(response).to redirect_to(wait_for_eligibility_response_financial_assistance_application_path(application))
      end
    end

    it "should render step if model is not saved" do
      post :step, id: application.id
      expect(response).to render_template 'workflow/step'
    end
  end

  context "generate_payload" do
    it "should execute action generate_payload" do
      allow(controller).to receive(:render_to_string).with(
        "events/financial_assistance_application", {:formats => ["xml"], :locals => { :financial_assistance_application => application }}).and_return(application)
    end
  end

  context "GET copy" do
    context "when there is not response from eligibility service" do
      before do
        family.applications.each {|app| app.update_attributes(aasm_state: "determined")}
      end

      it 'should copy applicant and redirect to financial assistance application edit path' do
        get :copy, id: application.id
        family.reload
        existing_app_ids = [application.id, application2.id]
        copy_app = application.family.applications.reject {|app| existing_app_ids.include? app.id}.first
        expect(response).to redirect_to(edit_financial_assistance_application_path(copy_app.id))
      end
    end

    context "when there is response from eligibility service" do
      include L10nHelper
      include ActionView::Helpers::TranslationHelper

      before do
        allow(controller).to receive(:call_service)
        controller.instance_variable_set(:@assistance_status, false)
        controller.instance_variable_set(:@message, "101")
        get :copy, id: application.id
      end

      let(:message) {l10n("faa.acdes_lookup")}

      it 'should not copy applicant and redirect to financial_assistance_applications_path' do
        expect(response).to redirect_to(financial_assistance_applications_path)
      end

      it 'should not copy applicant and throw message' do
        expect(flash[:error].to_s).to match(message)
      end
    end
  end

  context "GET help_paying_coverage" do
    it 'should assign application id to transaction id' do
      get :help_paying_coverage, id: application.id
      expect(assigns(:transaction_id)).to eq application.id.to_s
    end
  end

  context "GET help_paying_coverage" do

    context "'Yes' to is_applying_for_assistance" do
      it "should redirect to app checklist if 'yes' is answered to is_applying_for_assistance" do
        get :get_help_paying_coverage_response, exit_after_method: false, is_applying_for_assistance: "true"
        expect(response).to redirect_to(application_checklist_financial_assistance_applications_path)
        expect(family.applications.where(aasm_state: "draft").first.applicants.count).to eq 1
      end

      let(:person1) { FactoryGirl.create(:person)}
      let(:family_member){FactoryGirl.build(:family_member, family: family, person: person1)}

      it "should redirect to app checklist by creating applicants to all family members of the family if answered 'yes'" do
        family.applications.each { |app| app.update_attributes(aasm_state: "determined") }
        person.person_relationships.create(predecessor_id: person.id, :successor_id => person1.id, :kind => "spouse", family_id: family.id)
        family_member.save
        family.save
        get :get_help_paying_coverage_response, exit_after_method: false, is_applying_for_assistance: "true"
        family.reload
        expect(family.applications.where(aasm_state: "draft").first.applicants.count).to eq 2
        expect(response).to redirect_to(application_checklist_financial_assistance_applications_path)
      end
    end

    it "should redirect to insured family memebers if 'no' is answered to is_applying_for_assistance" do
      get :get_help_paying_coverage_response, exit_after_method: false, is_applying_for_assistance: "false"
      expect(response).to redirect_to(insured_family_members_path(consumer_role_id: person.consumer_role.id))
    end

    it "should remain on the same page and flash an error message if nothing is answered to is_applying_for_assistance" do
      get :get_help_paying_coverage_response, exit_after_method: false, is_applying_for_assistance: nil
      expect(response).to redirect_to(help_paying_coverage_financial_assistance_applications_path)
      expect(flash[:error]).to match(/Please choose an option before you proceed./)
    end
  end

  context "uqhp_flow" do
    it "should redirect to insured family memebers" do
      get :uqhp_flow
      expect(family.applications.where(aasm_state: "draft").count).to eq 0
      expect(response).to redirect_to(insured_family_members_path(consumer_role_id: person.consumer_role.id))
    end
  end

  context "GET review_and_submit" do
    it 'should  review and submit page' do
      application.update_attributes(:aasm_state => "draft")
      get :review_and_submit, id: application.id
      expect(assigns(:consumer_role)).to eq person.consumer_role
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "GET review" do
    it "should be successful" do
      application.update_attributes(:aasm_state => "submitted")
      get :review, id: application.id
      expect(assigns(:application)).to eq application
    end

    it "should redirect to applications page" do
      get :review, id: FinancialAssistance::Application.new.id
      expect(response).to redirect_to(financial_assistance_applications_path)
    end
  end

  context "GET wait_for_eligibility_response" do
    it "should redirect to eligibility_response_error if doesn't find the ED on wait_for_eligibility_response page" do
      get :wait_for_eligibility_response, id: application.id
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
    end
  end

  context "GET eligibility_results" do
    it 'should get eligibility results' do
      get :eligibility_results, {:id => application.id, :cur=>1}
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "GET application_publish_error" do
    it 'should get application publish error' do
      get :application_publish_error, id: application.id
      expect(assigns(:family)).to eq family
      expect(assigns(:application)).to eq application
      expect(response).to render_template(:financial_assistance)
    end
  end

  context "check eligibility results received" do
    it "should return true if the Header of the response doesn't has the success status code" do
      get :check_eligibility_results_received, id: application.id
      expect(response.body).to eq "false"
    end

    it 'should return true if the Header of the response has the success status code' do
    application.update_attributes(determination_http_status_code: 200)
      get :check_eligibility_results_received, id: application.id
      expect(response.body).to eq "true"
    end
  end
end
