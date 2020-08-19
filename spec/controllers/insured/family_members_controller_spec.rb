require 'rails_helper'

RSpec.describe Insured::FamilyMembersController do
  before :all do
    DatabaseCleaner.clean
  end

  let(:user) { instance_double("User", :primary_family => test_family, :person => person) }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }
  let(:test_family) { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:person) { test_family.primary_family_member.person }
  let(:published_plan_year)  { FactoryGirl.build(:plan_year, aasm_state: :published)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person ) }
  let(:employee_role_id) { employee_role.id }
  let(:census_employee) { FactoryGirl.create(:census_employee) }

  before do
    employer_profile.plan_years << published_plan_year
    employer_profile.save
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end


  describe "GET index" do
    context 'normal' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(@controller).to receive(:set_family)
        @controller.instance_variable_set(:@person, person)
        @controller.instance_variable_set(:@family, test_family)
        allow(test_family).to receive(:build_relationship_matrix).and_return([])
        allow(test_family).to receive(:find_missing_relationships).and_return([])
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
        get :index, :employee_role_id => employee_role_id
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq test_family
      end
    end

    context 'with no referer' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(@controller).to receive(:set_family)
        @controller.instance_variable_set(:@person, person)
        @controller.instance_variable_set(:@family, test_family)
        allow(test_family).to receive(:build_relationship_matrix).and_return([])
        allow(test_family).to receive(:find_missing_relationships).and_return([])
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return(nil)
        get :index, :employee_role_id => employee_role_id
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq test_family
      end
    end

    # Some times Effective dates vary even for the next day. So creating a new SEP & re-calculating effective on dates
    context "with sep_id in params" do

      let(:sep) { FactoryGirl.create :special_enrollment_period, family: test_family }
      let(:dup_sep) { double("SpecialEnrPeriod", qle_on: TimeKeeper.date_of_record - 5.days) }

      before :each do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return(nil)
      end

      it "should not duplicate sep if using current sep on same day" do
        get :index, :sep_id => sep.id, qle_id: sep.qualifying_life_event_kind_id
        expect(assigns(:sep)).to eq sep
      end

      context "when using old active sep" do

        before do
          sep.update_attributes(submitted_at: TimeKeeper.datetime_of_record - 1.day)
        end

        it "should not get assign with old sep" do
          get :index, :sep_id => sep.id, qle_id: sep.qualifying_life_event_kind_id
          expect(assigns(:sep)).not_to eq sep
        end

        it "should duplicate sep" do
          allow(controller).to receive(:duplicate_sep).and_return dup_sep
          get :index, :sep_id => sep.id, qle_id: sep.qualifying_life_event_kind_id
          expect(assigns(:sep)).to eq dup_sep
        end

        it "should have the today's date as submitted_at" do
          get :index, :sep_id => sep.id, qle_id: sep.qualifying_life_event_kind_id
          expect(assigns(:sep).submitted_at.to_date).to eq TimeKeeper.date_of_record
        end

        it "qle market kind is should be shop" do
          expect(qle.market_kind).to eq "shop"
        end
      end
    end

    it "with qle_id" do
      allow(person).to receive(:primary_family).and_return(test_family)
      allow(person).to receive(:broker_role).and_return(nil)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(employee_role).to receive(:save!).and_return(true)
      allow(employer_profile).to receive(:published_plan_year).and_return(published_plan_year)
      sign_in user
      allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
      expect{
        get :index, employee_role_id: employee_role_id, qle_id: qle.id, effective_on_kind: 'date_of_event', qle_date: '10/10/2015', published_plan_year: '10/10/2015'
      }.to change(test_family.special_enrollment_periods, :count).by(1)
    end
  end

  describe "GET show" do
    let(:dependent) { double("Dependent") }
    let(:app) { double("App") }
    let(:family_member) {double("FamilyMember", id: double("id"), family: double("Family", application_in_progress: double("App")))}

    before(:each) do
      allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
      allow(dependent).to receive(:family).and_return(test_family)
      allow(dependent).to receive(:family_member).and_return(family_member)
      allow(test_family).to receive(:build_relationship_matrix).and_return([])
      allow(test_family).to receive(:find_missing_relationships).and_return([])
      sign_in(user)
      get :show, :id => family_member.id
    end

    it "should render show templage" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
    end
  end

  describe "GET new" do
    let(:family_id) { "addbedddedtotallyafamiyid" }
    let(:dependent) { double }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with({:family_id => family_id}).and_return(dependent)
      get :new, :family_id => family_id
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

    it "assigns the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end
  end

  describe "POST create" do
    let(:address) { double }
    let(:family_member) { double("FamilyMember")}
    let(:dependent) { double(addresses: [address], family_member: family_member, same_with_primary: true) }
    let(:dependent_properties) { { :family_id => "saldjfalkdjf"} }
    let(:save_result) { false }
    let(:test_family) { FactoryGirl.build(:family, :with_primary_family_member) }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with(dependent_properties).and_return(dependent)
      allow(dependent).to receive(:save).and_return(save_result)
      allow(dependent).to receive(:address=)
      allow(dependent).to receive(:family_id).and_return(dependent_properties)
      allow(dependent).to receive(:family).and_return(test_family)
      allow(dependent).to receive(:copy_finanacial_assistances_application)
      allow(test_family).to receive(:build_relationship_matrix).and_return([])
      allow(test_family).to receive(:find_missing_relationships).and_return([])
      allow(Family).to receive(:find).with(dependent_properties).and_return(test_family)
      allow(family_member).to receive_message_chain(:family, :application_in_progress).and_return nil
      post :create, :dependent => dependent_properties
    end

    describe "with an invalid dependent" do
      it "should assign the dependent" do
        expect(assigns(:dependent)).to eq dependent
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end

    describe "with a valid dependent" do
      let(:save_result) { true }

      it "should assign the dependent" do
        expect(assigns(:dependent)).to eq dependent
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "with a valid dependent but not applying for coverage" do
      let(:save_result) { true }
      let(:dependent_properties) { { "is_applying_coverage" => "false" } }

      it "should assign the dependent" do
        expect(assigns(:dependent)).to eq dependent
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "when update_vlp_documents failed" do
      before :each do
        allow(controller).to receive(:update_vlp_documents).and_return false
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end

      it "should get addresses as an array" do
        expect(response).to render_template("new")
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end
  end

  describe "For member addition/deletion (post create or delete destroy)" do

    let!(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:application) {FactoryGirl.create(:application, family: family)}
    let!(:household) {family.households.first}
    let!(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
    let!(:family_member) {family.primary_applicant}
    let!(:applicant) {FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member.id)}
    let(:params) {{
        "consumer_role_id"=>"",
        "employee_role_id"=>"",
        "dependent"=>
            {"first_name"=>"mem",
             "middle_name"=>"",
             "last_name"=>"one",
             "is_applying_coverage"=>"true",
             "dob"=>"1990-06-01",
             "ssn"=>"213-21-3312",
             "no_ssn"=>"0",
             "gender"=>"female",
             "relationship"=>"domestic_partner",
             "us_citizen"=>"true",
             "naturalized_citizen"=>"false",
             "indian_tribe_member"=>"false",
             "tribal_id"=>"",
             "is_incarcerated"=>"false",
             "ethnicity"=>["", "", "", "", "", "", ""],
             "is_consumer_role"=>"true",
             "same_with_primary"=>"true",
             "addresses"=>
                 {"0"=>{"kind"=>"home", "address_1"=>"", "address_2"=>"", "city"=>"", "state"=>"", "zip"=>""},
                  "1"=>{"kind"=>"mailing", "address_1"=>"", "address_2"=>"", "city"=>"", "state"=>"", "zip"=>""}},
             "is_homeless"=>"0",
             "is_temporarily_out_of_state"=>"0",
             "family_id"=> family.id},
        "jq_datepicker_ignore_dependent"=>{"dob"=>"06/01/1990"},
        "immigration_doc_type"=>"",
        "naturalization_doc_type"=>"",
        "form_for_consumer_role"=>"false",
        "button"=>"",
        "controller"=>"insured/family_members"}}

    before :each do
      sign_in(user)
      allow(STDOUT).to receive(:puts)
    end

    context "for member addition" do
      it "should copy application if previous application is not in draft state" do
        expect(family.applications.count).to eq 1
        post :create, params
        expect(family.applications.count).to eq 2
      end

      it "should not copy application if previous application is in draft state" do
        family.applications.first.update_attributes(aasm_state: "draft")
        expect(family.applications.count).to eq 1
        post :create, params
        expect(family.applications.count).to eq 1
      end

      it "should not copy application if there are no applications" do
        family.applications.first.destroy!
        family.reload
        expect(family.applications.count).to eq 0
        post :create, params
        expect(family.applications.count).to eq 0
      end
    end

    context "for member deletion" do
      let!(:person2) { FactoryGirl.create(:person) }
      let!(:family_member2){FactoryGirl.create(:family_member, family: family,is_primary_applicant: false, is_active: true, person: person2)}


      it "should copy application if previous application is not in draft state" do
        expect(family.applications.count).to eq 1
        delete :destroy, :id => family.family_members[1].id
        expect(family.applications.count).to eq 2
      end

      it "should not copy application if previous application is in draft state" do
        family.applications.first.update_attributes(aasm_state: "draft")
        expect(family.applications.count).to eq 1
        delete :destroy, :id => family.family_members[1].id
        expect(family.applications.count).to eq 1
      end

      it "should not copy application if there are no applications" do
        family.applications.first.destroy!
        family.reload
        expect(family.applications.count).to eq 0
        delete :destroy, :id => family.family_members[1].id
        expect(family.applications.count).to eq 0
      end
    end
  end


  describe "DELETE destroy" do
    let!(:test_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:family_member) { test_family.primary_applicant }
    let!(:application) { FactoryGirl.create(:application, aasm_state: "draft", family: test_family) }
    let!(:applicant) { FactoryGirl.create(:applicant, family_member_id: family_member.id, application: application)}
    let!(:dependent) { double }
    let!(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(dependent).to receive(:family_member).and_return(family_member)
      allow(dependent).to receive(:copy_finanacial_assistances_application)
    end

    it "should destroy the dependent" do
      expect(dependent).to receive(:destroy!)
      delete :destroy, :id => dependent_id
    end

    it "should render the index template" do
      allow(dependent).to receive(:destroy!)
      delete :destroy, :id => dependent_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe "GET edit" do
    let(:dependent) { double(family_member: double) }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      get :edit, :id => dependent_id
    end

    it "should assign the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end

    it "should render the edit template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update" do
    let(:address) { double }
    let(:dependent) { double(addresses: [address], family_member: double("FamilyMember", family: double("Family", application_in_progress: double("App"))), same_with_primary: 'true') }
    let(:dependent_id) { "234dlfjadsklfj" }
    let(:dependent_properties) { { "first_name" => "lkjdfkajdf" } }
    let(:update_result) { false }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(dependent).to receive(:update_attributes).with(dependent_properties).and_return(update_result)
      allow(dependent).to receive(:family_id).and_return(test_family.id)
      allow(Family).to receive(:find).with(test_family.id).and_return(test_family)
      allow(address).to receive(:is_a?).and_return(true)
      allow(dependent).to receive(:same_with_primary=)
      allow(dependent).to receive(:addresses=)
    end

    describe "with an invalid dependent" do
      it "should render the edit template" do
        expect(Address).to receive(:new).twice
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end

      it "addresses should be an array" do
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end

    describe "with a valid dependent" do
      let(:test_family) { FactoryGirl.create(:family, :with_primary_family_member) }
      let(:family_member) {  test_family.primary_applicant }
      let(:update_result) { true }

      before :each do
        allow(dependent).to receive(:family_member).and_return(family_member)
      end

      it "should render the show template" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end

      it "should render the edit template when update_vlp_documents failure" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end
end
