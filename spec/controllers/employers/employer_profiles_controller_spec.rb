require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController do

  describe "GET index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:employer_profile1) { FactoryGirl.create(:employer_profile) }
    let(:employer_profile2) { FactoryGirl.create(:employer_profile) }

    context 'when broker agency id present' do
      it 'should return employers for the broker agency', dbclean: :after_each do
        allow(user).to receive(:person).and_return(person)
        allow(controller).to receive(:find_mailbox_provider).and_return(true)
        sign_in(user)
        employer_profile1 = FactoryGirl.create(:employer_profile)
        employer_profile2 = FactoryGirl.create(:employer_profile)
        organization = FactoryGirl.create(:organization)
        broker_agency_profile = FactoryGirl.build(:broker_agency_profile, organization: organization)
        broker_agency_account = FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile)
        employer_profile1.broker_agency_accounts << broker_agency_account
        employer_profile1.save!
        get :index, broker_agency_id: broker_agency_account.broker_agency_profile_id
        expect(response).to have_http_status(:success)
        expect(assigns(:orgs).count).to eq(1)
        expect(assigns(:orgs).first).to eq(employer_profile1.organization)
      end
    end

    context 'when broker agency id not present' do
      it 'should return all the employers in the system', dbclean: :after_each do
        allow(user).to receive(:person).and_return(person)
        allow(controller).to receive(:find_mailbox_provider).and_return(true)
        sign_in(user)
        employer_profile1 = FactoryGirl.create(:employer_profile)
        employer_profile2 = FactoryGirl.create(:employer_profile)
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:orgs).count).to eq(2)
      end
    end
  end

  describe "GET new" do
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false)}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?).and_return(false)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:has_active_employer_staff_role?).and_return(false)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "REDIRECT to my account if employer staff role present" do
    let(:user) { double("user")}
    let(:person) { double(:employer_staff_roles => [double("person", :employer_profile_id => double)])}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_employer_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:has_active_employer_staff_role?).and_return(true)
      allow(person).to receive(:active_employer_staff_roles).and_return([double("employer_staff_role", employer_profile_id: 77)])
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET show" do
    let(:user) { double(
      "user",
      :person => person,
      :last_portal_visited => "true",
      :save => true,
      :has_hbx_staff_role? => false,
      :has_broker_role? => false,
      :has_broker_agency_staff_role? => false,
      :has_employer_staff_role? => true
    ) }
    let(:person) { double("person", :employer_staff_roles => [employer_staff_role]) }
    let(:employer_staff_role) { double(:employer_profile_id => employer_profile.id) }
    let(:plan_year) { FactoryGirl.create(:plan_year) }
    let(:employer_profile) { plan_year.employer_profile}

    let(:policy) {double("policy")}
    before(:each) do
      allow(::AccessPolicies::EmployerProfile).to receive(:new).and_return(policy)
      allow(policy).to receive(:is_broker_for_employer?).and_return(false)
      allow(policy).to receive(:authorize_show).and_return(true)
      allow(user).to receive(:last_portal_visited=).and_return("true")
      employer_profile.plan_years = [plan_year]
      sign_in(user)
    end

    it "should render the show template" do
      get :show, id: employer_profile.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
      expect(assigns(:current_plan_year)).to eq employer_profile.active_plan_year
    end

    it "should render 404 with invalid id" do
      get :show, id: "invalid_id"
      expect(response).to have_http_status(404)
      expect(response).to render_template(:file => "#{Rails.root}/public/404.html")
    end

    it "should get plan years" do
      get :show, id: employer_profile.id
      expect(assigns(:current_plan_year)).to eq employer_profile.active_plan_year
    end

    it "should get invoice when tab invoice selected" do
      get :show, id: employer_profile.id , tab: "invoice"
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
    end

    it "should get default status" do
      xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees'}
      expect(assigns(:status)).to eq "active"
    end

    it "should get 20 census_employees without page params" do
      30.times do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, last_name: "#{('A'..'Z').to_a.sample}last_name")
      end
      xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees'}
      expect(assigns(:total_census_employees_quantity)).to eq employer_profile.census_employees.active.count
      expect(assigns(:census_employees).count).to eq 20
      expect(assigns(:census_employees)).to eq employer_profile.census_employees.active.sorted.search_by(employee_name: '').to_a.first(20)
    end

   it "should get employees with names starting with C and then B" do
      10.times do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, last_name: "A#{('A'..'Z').to_a.sample}last_name")
      end
      15.times do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, last_name: "B#{('A'..'Z').to_a.sample}last_name")
      end
      11.times do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, last_name: "C#{('A'..'Z').to_a.sample}last_name")
      end
      xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees', page: 'C'}
      expect(assigns(:census_employees).count).to eq 11
      xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees', page: 'B'}
      expect(assigns(:census_employees).count).to eq 15
    end

    it "search by employee name" do
      employer_profile.census_employees.delete_all
      census_employee = FactoryGirl.create(:census_employee, employer_profile: employer_profile)

      xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees'}
      expect(assigns(:census_employees).count).to eq 1
      expect(assigns(:census_employees)).to eq [census_employee]
    end

    #it "get avaliable_employee_names for autocomplete employee name" do
    #  xhr :get,:show_profile, {employer_profile_id: employer_profile.id.to_s, tab: 'employees'}
    #  expect(assigns(:avaliable_employee_names)).to eq employer_profile.census_employees.sorted.map(&:full_name).uniq
    #end
  end


  describe "GET show" do
    let(:user) { FactoryGirl.create(:user) }
    let(:person){ FactoryGirl.create(:person) }
    let(:employer_profile) {instance_double("EmployerProfile", id: double("id"))}
    let(:hbx_enrollment) {
      instance_double("HbxEnrollment",
        total_premium: 345,
        total_employee_cost: 145,
        total_employer_contribution: 200
        )
    }

    let(:plan_year) {
      instance_double("PlanYear",
        additional_required_participants_count: 10
        )
    }

    let(:policy) {double("policy")}

    context "it should return published plan year " do
      let(:broker_agency_account) { FactoryGirl.build_stubbed(:broker_agency_account) }

      before do
        allow(::AccessPolicies::EmployerProfile).to receive(:new).and_return(policy)
        allow(policy).to receive(:authorize_show).and_return(true)
        allow(user).to receive(:last_portal_visited=).and_return("true")
        allow(user).to receive(:save).and_return(true)
        allow(EmployerProfile).to receive(:find).and_return(employer_profile)
        allow(employer_profile).to receive(:show_plan_year).and_return(plan_year)
        allow(employer_profile).to receive(:enrollments_for_billing).and_return([hbx_enrollment])
        allow(employer_profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        allow(employer_profile).to receive_message_chain(:organization ,:documents).and_return([])
        sign_in(user)
      end

      it "should render the show template" do
        allow(user).to receive(:person).and_return(person)
        get :show, id: employer_profile.id, tab: "home"
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
        expect(assigns(:current_plan_year)).to eq plan_year
      end


      it "should get announcement" do
        FactoryGirl.create(:announcement, content: "msg for Employer", audiences: ['Employer'])
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_employer_staff_role?).and_return true
        get :show, id: employer_profile.id, tab: "home"
        expect(flash.now[:warning]).to eq ["msg for Employer"]
      end
    end
  end

  describe "GET welcome" do
    let(:user) { double("user")}
    let(:person) { double("Person")}

    it "renders the 'welcome' template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_employer_staff_role?)
      sign_in(user)
      get :welcome
      expect(response).to have_http_status(:success)
      expect(response).to render_template("welcome")
    end
  end

  describe "GET search" do
    let(:user) { double("user")}
    let(:person) { double("Person")}
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

  describe "GET index" do
    let(:organization_search_criteria) { double }
    let(:organization_employer_criteria) { double }
    let(:found_organization) { double(:employer_profile => employer) }
    let(:criteria_page_results) { [found_organization] }
    let(:employer) { double }
    let(:employer_list) { [employer] }
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      allow(Organization).to receive(:search).with(nil).and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(organization_employer_criteria)
      allow(organization_employer_criteria).to receive(:where).and_return(criteria_page_results)
      allow(controller).to receive(:page_alphabets).and_return(["A", "B"])
      get :index
    end

    it "assigns the list of employers" do
      expect(assigns(:employer_profiles)).to eq employer_list
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end
  end

  describe "GET index search" do
    let(:organization_search_criteria) { double }
    let(:criteria_page_results) { [double(:employer_profile => employer)] }
    let(:employer) { double }
    let(:employer_list) { [employer] }
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      allow(Organization).to receive(:search).with("A Name").and_return(organization_search_criteria)
      allow(organization_search_criteria).to receive(:exists).with({employer_profile: true}).and_return(criteria_page_results)
      get :index, q: "A Name", page: "A"
    end

    it "assigns the list of employers" do
      expect(assigns(:employer_profiles)).to eq employer_list
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end

  end

  describe "POST create" do
    let(:user){ double("User", :idp_verified? => true) }
    let(:person){ double("Person", :id => "some person id") }
    let(:phone_attributes) { {
      :kind => "phone kind",
      :number => "phone number",
      :area_code => "area code",
      :extension => "extension"
    } }

    let(:address_attributes) { {
      :kind => "address kind",
      :address_1 => "address 1",
      :address_2 => "address 2",
      :city => "city",
      :state => "MD",
      :zip => "22222"
    } }

    let(:organization_params) {
      {
          :entity_kind => "an entity kind",
          :dba => "a dba",
          :fein => "123456789",
          :legal_name => "a legal name",
        :office_locations_attributes => {
          "0" => {
            :phone_attributes => phone_attributes,
            :address_attributes => address_attributes
          }
        }
      }
    }

    let(:save_result) { false }

    let(:organization) { double(:employer_profile => double) }

    before(:each) do
      @user = FactoryGirl.create(:user)
      p=FactoryGirl.create(:person, user: @user)
      @hbx_staff_role = FactoryGirl.create(:hbx_staff_role, person: p)
      

      allow(@user).to receive(:switch_to_idp!)
      allow(Forms::EmployerProfile).to receive(:new).and_return(organization)
      allow(organization).to receive(:save).and_return(save_result)
      
    end
    describe 'updateable organization' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in @user
        post :create, :organization => organization_params
      end
      describe "given an invalid employer profile" do
        it "assigns the organization" do
          expect(assigns(:organization)).to eq organization
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "renders the 'new' template" do
          expect(response).to render_template("new")
        end
      end

      describe "given a valid employer profile" do
        let(:save_result) { true }

        it "assigns the organization" do
          expect(assigns(:organization)).to eq organization
        end

        it "returns http redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    describe 'update organization not allowed' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: false))
        sign_in @user
        post :create, :organization => organization_params
      end
      

      describe "given a valid employer profile" do
        let(:save_result) { true }

        it "has an error message" do
           expect(flash[:error]).to match(/Access not allowed/)
        end

        it "returns http redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end
    end

  end

  describe "POST create" do
    let(:user) { double("User", :idp_verified? => true) }
    let(:person) { double("Person", :id => "SOME PERSON ID") }
    let(:employer_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:found_employer) { double("test", :save => validation_result, :employer_profile => double) }
    let(:office_locations){[double(address: double("address"), phone: double("phone"), email: double("email"))]}
    let(:organization) {double(office_locations: office_locations)}

    before(:each) do
      @user = FactoryGirl.create(:user)
      p=FactoryGirl.create(:person, user: @user)
      @hbx_staff_role = FactoryGirl.create(:hbx_staff_role, person: p)    
      allow(@hbx_staff_role).to receive_message_chain('permission.modify_employer').and_return(true)
      sign_in @user
      allow(Forms::EmployerProfile).to receive(:new).and_return(found_employer)
      
      allow(@user).to receive(:switch_to_idp!)
#      allow(EmployerProfile).to receive(:find_by_fein).and_return(found_employer)
#      allow(found_employer).to receive(:organization).and_return(organization)
      post :create, :organization => employer_parameters
    end

    context "given invalid parameters" do
      let(:validation_result) { true }

      it "renders the 'edit' template" do
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "POST match" do
    let(:employer_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:found_employer) { [] }
    let(:user) { double("User")}
    let(:person) { double("Person") }
    let(:create_employer_params) { "" }
    let(:mock_employer_candidate) { instance_double("Forms::EmployerCandidate", :valid? => validation_result) }

    before(:each) do
      sign_in user
      allow(user).to receive(:person).and_return(person)
      allow(Forms::EmployerCandidate).to receive(:new).with(employer_parameters).and_return(mock_employer_candidate)
      allow(mock_employer_candidate).to receive(:match_employer).and_return(found_employer)
      post :match, :employer_profile => employer_parameters, :create_employer => create_employer_params
    end

    context "given invalid parameters" do
      let(:validation_result) { false }

      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:employer_profile]).to eq mock_employer_candidate
      end
    end

    context "given valid parameters render 'no_match' template" do
      let(:validation_result) { true }

      it "renders the 'no_match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("no_match")
        expect(assigns[:employer_candidate]).to eq mock_employer_candidate
      end
    end

    context "given valid parameters render 'match' template" do
      let(:validation_result) { true }
      let(:found_employer) { FactoryGirl.create(:employer_profile) }

      it "renders the 'match' template" do
        allow(user).to receive(:person).and_return(person)
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns[:employer_candidate]).to eq mock_employer_candidate
        expect(assigns(:employer_profile)).to eq found_employer
      end
    end

    context "given valid parameters and create_employer" do
      let(:employer_parameters) { { :sic_code => "SOMDFINKETHING" } }
      let(:validation_result) { true }
      let(:create_employer_params) { true }

      it "renders the 'edit' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end

  describe "PUT update" do
    let(:user) { double("user")}
    let(:employer_profile) { double("EmployerProfile") }
    let(:organization) { double("Organization", id: "test") }
    let(:person) { FactoryGirl.build(:person) }
    let(:staff_roles){ [person] }
    let(:organization_params) {
      {
          :entity_kind => "an entity kind",
          :dba => "a dba",
          :fein => "123456789",
          :legal_name => "a legal name",
      }
    }


    before do
      allow(user).to receive(:has_employer_staff_role?).and_return(true)
      allow(user).to receive(:roles).and_return(["employer_staff"])
      allow(user).to receive(:person).and_return(person)
      allow(Organization).to receive(:find).and_return(organization)
      allow(organization).to receive(:employer_profile).and_return(employer_profile)
      allow(organization).to receive(:office_locations).and_return(true)
      allow(organization).to receive(:assign_attributes).and_return(true)
      allow(organization).to receive(:save).and_return(true)
      allow(organization).to receive(:update_attributes).and_return(true)

      allow(controller).to receive(:employer_params).and_return({"dob"=>"07/16/1980","first_name"=>"test"})

      allow(controller).to receive(:organization_profile_params).and_return({})
      allow(controller).to receive(:employer_profile_params).and_return({})
      allow(controller).to receive(:sanitize_employer_profile_params).and_return(true)
      allow(employer_profile).to receive(:staff_roles).and_return(staff_roles)
      allow(employer_profile).to receive(:match_employer).and_return person
    end

    it "should redirect" do
      allow(user).to receive(:save).and_return(true)
      allow(person).to receive(:employer_staff_roles).and_return([EmployerStaffRole.new])
      allow(organization).to receive(:errors).and_return nil
      sign_in(user)
      expect(Organization).to receive(:find)

      put :update, id: organization.id
      expect(response).to be_redirect
    end

    it "should show error msg when save failed" do
      allow(user).to receive(:save).and_return(true)
      allow(person).to receive(:employer_staff_roles).and_return([EmployerStaffRole.new])
      sign_in(user)
      expect(Organization).to receive(:find)
      allow(organization).to receive(:update_attributes).and_return false
      allow(organization).to receive(:errors).and_return double(full_messages: ["Can't have multiple primary addresses"])

      put :update, id: organization.id
      expect(response).to be_redirect
      expect(flash[:error]).to match "Can't have multiple primary addresses"
    end

    context "given current user is invalid" do
      it "should render edit template" do
        allow(user).to receive(:save).and_return(false)
        sign_in(user)
        put :update, id: organization.id
        expect(response).to be_redirect
      end
    end

     context "given the company have managing staff" do
      it "should render edit template" do
        allow(user).to receive(:save).and_return(true)
        sign_in(user)
        put :update, id: organization.id
        expect(response).to be_redirect
      end
    end
    # Refs #3898 Person information cannot be updated!
    #it "should update person info" do
    #  allow(user).to receive(:save).and_return(true)
    #  sign_in(user)
    #  expect(Organization).to receive(:find)
    #  put :update, id: organization.id, first_name: "test", organization: organization_params
    #  expect(person.first_name).to eq "test"
    #  expect(response).to be_redirect
    #end
  end

  #describe "DELETE destroy" do
  #  let(:user) { double("user")}
  #  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  #  it "should redirect" do
  #    sign_in(user)
  #    expect {
  #      delete :destroy, id: employer_profile.id
  #    }.to change(EmployerProfile, :count).by(-1)
  #    expect(response).to be_redirect
  #  end
  #end

  describe "GET export_census_employees" do
    let(:user) { FactoryGirl.create(:user) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

   it "should export cvs" do
     sign_in(user)
     get :export_census_employees, employer_profile_id: employer_profile, format: :csv
     expect(response).to have_http_status(:success)
   end

  end
end
