require 'rails_helper'

RSpec.describe Exchanges::HbxProfilesController, dbclean: :after_each do

  describe "various index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile")}

    before :each do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders index" do
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/index")
    end

    it "renders broker_agency_index" do
      xhr :get, :broker_agency_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/broker_agency_index")
    end

    it "renders issuer_index" do
      xhr :get, :issuer_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/issuer_index")
    end

    it "renders issuer_index" do
      xhr :get, :product_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/product_index")
    end
  end

  describe "binder methods" do
    let(:user) { double("user")}
    let(:person) { double("person")}
    let(:hbx_profile) { double("HbxProfile") }
    let(:hbx_staff_role) { double("hbx_staff_role", permission: FactoryGirl.create(:permission))}
    let(:employer_profile){ FactoryGirl.create(:employer_profile, aasm_state: "enrolling") }

    before(:each) do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders binder_index" do
      xhr :get, :binder_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/binder_index")
    end

    it "updates employers state to binder paid" do
      post :binder_paid, :employer_profile_ids => [employer_profile.id]
      expect(flash[:notice]).to eq 'Successfully submitted the selected employer(s) for binder paid.'
    end

    it "should render json template" do
      get :binder_index_datatable, {format: :json}
      expect(response).to render_template("exchanges/hbx_profiles/binder_index_datatable")
    end

  end

  describe "new" do
    let(:user) { double("User")}
    let(:person) { double("Person")}

    it "renders new" do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "inbox" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}

    it "renders inbox" do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      xhr :get, :inbox, id: hbx_profile.id
      expect(response).to have_http_status(:success)
    end

  end

  describe "employer_invoice" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}
    let(:search_params){{"value"=>""}}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders employer_invoice datatable" do
      xhr :get, :employer_invoice
      expect(response).to have_http_status(:success)
    end

    it "renders employer_invoice datatable payload" do
      xhr :post, :employer_invoice_datatable, :search => search_params
      expect(response).to have_http_status(:success)
    end

  end

  describe "#create" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}
    let(:organization){ Organization.new }
    let(:organization_params) { {hbx_profile: {organization: organization.attributes}}}

    before :each do
      sign_in(user)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(Organization).to receive(:new).and_return(organization)
      allow(organization).to receive(:build_hbx_profile).and_return(hbx_profile)
    end

    it "create new organization if params valid" do
      allow(hbx_profile).to receive(:save).and_return(true)
      post :create, organization_params
      expect(response).to have_http_status(:redirect)
    end

    it "renders new if params invalid" do
      allow(hbx_profile).to receive(:save).and_return(false)
      post :create, organization_params
      expect(response).to render_template("exchanges/hbx_profiles/new")
    end
  end

  describe "#update" do
    let(:user) { FactoryGirl.create(:user, :hbx_staff) }
    let(:person) { double }
    let(:new_hbx_profile){ HbxProfile.new }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:hbx_profile_params) { {hbx_profile: new_hbx_profile.attributes, id: hbx_profile.id }}
    let(:hbx_staff_role) {double}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return person
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_role).to receive(:hbx_profile).and_return hbx_profile
      sign_in(user)
    end

    it "updates profile" do
      allow(hbx_profile).to receive(:update).and_return(true)
      put :update, hbx_profile_params
      expect(response).to have_http_status(:redirect)
    end

    it "renders edit if params not valid" do
      allow(hbx_profile).to receive(:update).and_return(false)
      put :update, hbx_profile_params
      expect(response).to render_template("edit")
    end
  end

  describe "#destroy" do
    let(:user){ double("User") }
    let(:person){ double("Person") }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:hbx_staff_role) {double}

    it "destroys hbx_profile" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_role).to receive(:hbx_profile).and_return hbx_profile
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(hbx_profile).to receive(:destroy).and_return(true)
      sign_in(user)
      delete :destroy, id: hbx_profile.id
      expect(response).to have_http_status(:redirect)
    end

  end

  describe "#check_hbx_staff_role" do
    let(:user) { double("user")}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end


  describe "Show" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :has_csr_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      session[:dismiss_announcements] = 'hello'
      sign_in(user)
    end

    it "renders 'show' " do
      get :show
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/show")
    end

    it "should clear session for dismiss_announcements" do
      get :show
      expect(session[:dismiss_announcements]).to eq nil
    end
  end

  describe "#generate_invoice" do
    let(:user) { double("user", :has_hbx_staff_role? => true)}
    let(:employer_profile) { double("EmployerProfile", id: double("id"))}
    let(:organization){ Organization.new }
    let(:hbx_enrollment) { FactoryGirl.build_stubbed :hbx_enrollment }

    before :each do
      sign_in(user)
      allow(organization).to receive(:employer_profile?).and_return(employer_profile)
      allow(employer_profile).to receive(:enrollments_for_billing).and_return([hbx_enrollment])
    end

    it "create new organization if params valid" do
      xhr :get, :generate_invoice, {"employerId"=>[organization.id]} ,  format: :js
      expect(response).to have_http_status(:success)
      # expect(organization.invoices.size).to eq 1
    end
  end

  describe "CSR redirection from Show" do
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :has_csr_role? => true)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_csr_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:csr).and_return true
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return false
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :show
    end

    it "redirects to agents/home " do
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET employer index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      expect(controller).to receive(:find_hbx_profile)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :employer_index
    end

    it "renders the 'employer index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("employers/employer_profiles/index")
    end
  end

  describe "GET family index" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}
    let(:csr_role) { double("csr_role", cac: false)}
    before :each do
      allow(person).to receive(:csr_role).and_return(double("csr_role", cac: false))
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
    end

    it "renders the 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      get :family_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("insured/families/index")
    end

    it "renders the 'families index' template for csr" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      get :family_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("insured/families/index")
    end

    it "redirects if not csr or hbx_staff 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(person).to receive(:csr_role).and_return(false)
      get :family_index
      expect(response).to redirect_to(root_url)
    end

    it "redirects if not csr or hbx_staff 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(person).to receive(:csr_role).and_return(double("csr_role", cac: true))
      get :family_index
      expect(response).to redirect_to(root_url)
    end
  end

  describe "GET configuration index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      expect(controller).to receive(:find_hbx_profile)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :configuration
    end

    it "should render the configuration partial" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:partial => 'exchanges/hbx_profiles/_configuration_index')
    end
  end

  describe "POST" do
    let(:user) { FactoryGirl.create(:user)}
    let(:person) { FactoryGirl.create(:person, user: user) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }
    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)
    end

    it "sends timekeeper a date" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)
      expect(TimeKeeper).to receive(:set_date_of_record).with( TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      post :set_date, :forms_time_keeper => { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      expect(response).to have_http_status(:redirect)
    end

    it "sends timekeeper a date and fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false))
      sign_in(user)
      expect(TimeKeeper).not_to receive(:set_date_of_record).with( TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      post :set_date, :forms_time_keeper => { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end

    it "update setting" do
      Setting.individual_market_monthly_enrollment_due_on
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)

      post :update_setting, :setting => {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 15}
      expect(response).to have_http_status(:redirect)
      expect(Setting.individual_market_monthly_enrollment_due_on).to eq 15
    end

    it "update setting fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false))
      sign_in(user)
      post :update_setting, :setting => {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 19}
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end
  end

  describe "GET edit_dob_ssn" do

    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile)}
    let(:permission_yes) { FactoryGirl.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryGirl.create(:permission, :can_update_ssn => false)}
    
    it "should return authorization error for Non-Admin users" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      xhr :get, :edit_dob_ssn, @params
      expect(response).to have_http_status(:success)
    end

    it "should render the edit_dob_ssn partial for logged in users with an admin role" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      xhr :get, :edit_dob_ssn, @params
      expect(response).to have_http_status(:success)
    end

  end


  describe "POST update_dob_ssn" do

    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile)}
    let(:permission_yes) { FactoryGirl.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryGirl.create(:permission, :can_update_ssn => false)}
    let(:invalid_ssn) { "234-45-839" }
    let(:valid_ssn) { "234-45-8390" }
    let(:valid_dob) { "03/17/1987" }

    it "should render back to edit_enrollment if there is a validation error on save" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:person=>{:pid => person.id, :ssn => invalid_ssn, :dob => valid_dob},:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(response).to render_template('edit_enrollment')
    end 

    it "should render update_enrollment if the save is successful" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person=>{:pid => person.id, :ssn => valid_ssn, :dob => valid_dob },:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(response).to render_template('update_enrollment')
    end 


    it "should return authorization error for Non-Admin users" do
      allow(user).to receive(:has_hbx_staff_role?).and_return false
      sign_in(user)
      xhr :get, :update_dob_ssn
      expect(response).not_to have_http_status(:success)
    end

  end

  describe "GET general_agency_index" do
    let(:user) { FactoryGirl.create(:user, roles: ["hbx_staff"]) }
    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should returns http success" do
      xhr :get, :general_agency_index, format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get general_agencies" do
      xhr :get, :general_agency_index, format: :js
      expect(assigns(:general_agency_profiles)).to eq Kaminari.paginate_array(GeneralAgencyProfile.filter_by())
    end
  end
end

