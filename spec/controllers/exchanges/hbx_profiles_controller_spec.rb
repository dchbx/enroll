require 'rails_helper'
require File.join(Rails.root, "components/benefit_sponsors/spec/support/benefit_sponsors_product_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Exchanges::HbxProfilesController, dbclean: :around_each do

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
      get :broker_agency_index, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/broker_agency_index_datatable.html.slim", "layouts/single_column")
    end

    xit "renders issuer_index" do
      get :issuer_index, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/issuer_index.html.slim", "layouts/single_column")
    end

    xit "renders issuer_index" do
      get :product_index, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/product_index.html.slim", "layouts/single_column")
    end
  end

  describe "binder methods" do
    let(:user) { double("user")}
    let(:person) { double("person")}
    let(:hbx_profile) { double("HbxProfile") }
    let(:hbx_staff_role) { double("hbx_staff_role", permission: FactoryBot.create(:permission))}
    let(:employer_profile){ FactoryBot.create(:employer_profile, aasm_state: "enrolling") }

    before(:each) do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders binder_index" do
      get :binder_index, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/binder_index")
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
      get :inbox, params: {id: hbx_profile.id}, xhr: true
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
      get :employer_invoice, xhr: true
      expect(response).to have_http_status(:success)
    end

    it "renders employer_invoice datatable payload" do
      post :employer_invoice_datatable, params: {search: search_params}, xhr: true
      expect(response).to have_http_status(:success)
    end

  end
=begin
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
    let(:user) { FactoryBot.create(:user, :hbx_staff) }
    let(:person) { double }
    let(:new_hbx_profile){ HbxProfile.new }
    let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
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
    let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
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
=end

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

  describe "#view_the_configuration_tab?" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:user_2) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}
    let(:admin_permission) { double("permission", name: "super_admin", view_the_configuration_tab: true)}
    let(:admin_permission_with_time_travel) { double("permission", name: "super_admin", can_submit_time_travel_request: true, modify_admin_tabs: true)}
    let(:staff_permission) { double("permission", name: "hbx_staff")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(hbx_staff_role).to receive(:can_submit_time_travel_request).and_return(false)
      allow(hbx_staff_role).to receive(:view_the_configuration_tab)
      allow(user).to receive(:permission).and_return(admin_permission)
    end

    it "should render the config index for a super admin" do
      allow(hbx_staff_role).to receive(:view_the_configuration_tab).and_return(true)
      allow(hbx_staff_role).to receive(:permission).and_return(admin_permission)
      allow(hbx_staff_role).to receive(:subrole).and_return(admin_permission.name)
      allow(admin_permission).to receive(:name).and_return(admin_permission.name)
      allow(admin_permission).to receive(:can_submit_time_travel_request).and_return(false)
      allow(admin_permission).to receive(:view_the_configuration_tab).and_return(true)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:view_the_configuration_tab?).and_return(true)
      allow(user).to receive(:can_submit_time_travel_request?).and_return(false)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      sign_in(user)
      get :configuration
      expect(response).to have_http_status(:success)
      post :set_date, params: {forms_time_keeper: { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }}
      expect(response).to have_http_status(:redirect)
    end

    it "should not render the config index for a not super admin" do
      allow(admin_permission).to receive(:view_the_configuration_tab).and_return(false)
      allow(staff_permission).to receive(:view_the_configuration_tab).and_return(true)
      allow(hbx_staff_role).to receive(:view_the_configuration_tab).and_return(false)
      allow(hbx_staff_role).to receive(:permission).and_return(staff_permission)
      allow(hbx_staff_role).to receive(:subrole).and_return(staff_permission.name)
      allow(staff_permission).to receive(:name).and_return(staff_permission.name)
      allow(user_2).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user_2).to receive(:person).and_return(person)

      allow(user_2).to receive(:permission).and_return(staff_permission)

      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      sign_in(user_2)
      get :configuration
      expect(response).to have_http_status(:success)
    end

    it "should not allow super admin to time travel" do
      allow(admin_permission).to receive(:view_the_configuration_tab).and_return(true)
      allow(staff_permission).to receive(:view_the_configuration_tab).and_return(true)
      allow(hbx_staff_role).to receive(:permission).and_return(staff_permission)
      allow(hbx_staff_role).to receive(:view_the_configuration_tab).and_return(true)
      allow(hbx_staff_role).to receive(:subrole).and_return(staff_permission.name)
      allow(admin_permission).to receive(:can_submit_time_travel_request).and_return(false)
      allow(user_2).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:view_the_configuration_tab?).and_return(true)
      allow(user_2).to receive(:view_the_configuration_tab?).and_return(false)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:permission).and_return(admin_permission)
      sign_in(user)
      post :set_date, params: {forms_time_keeper: { date_of_record:  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }}
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "Show" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :has_csr_role? => false, :last_portal_visited => nil)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:last_portal_visited=).with("http://test.host/exchanges/hbx_profiles")
      allow(user).to receive(:save)
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
    let(:hbx_enrollment) { FactoryBot.build_stubbed :hbx_enrollment }

    before :each do
      sign_in(user)
      allow(organization).to receive(:employer_profile?).and_return(employer_profile)
      allow(employer_profile).to receive(:enrollments_for_billing).and_return([hbx_enrollment])
    end

    it "create new organization if params valid" do
      get :generate_invoice, params: {"employerId"=>[organization.id], ids: [organization.id]}, format: :js, xhr: true
      expect(response).to have_http_status(:success)
      # expect(organization.invoices.size).to eq 1
    end
  end

  describe "GET edit_force_publish", :dbclean => :around_each do

    context "of an hbx super admin clicks Force Publish" do
      let(:site) do
        FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
      end
      let(:employer_organization) do
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,  "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site).tap do |org|
          benefit_sponsorship = org.employer_profile.add_benefit_sponsorship
          benefit_sponsorship.save
          org
        end
      end
      let(:person) do
        FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryBot.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:user) do
        FactoryBot.create(:user, person: person)
      end
      let(:benefit_sponsorship) do
        employer_organization.benefit_sponsorships.first
      end

      it "renders edit_force_publish" do
        sign_in(user)
        @params = {id: benefit_sponsorship.id.to_s, employer_actions_id: "employer_actions_#{employer_organization.employer_profile.id.to_s}", :format => 'js'}
        get :edit_force_publish, params: @params, xhr: true
        expect(response).to render_template('edit_force_publish')
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST force_publish", :dbclean => :around_each do

    context "of an hbx super admin clicks Submit in Force Publish window" do
      let(:site) do
        FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
      end
      let(:employer_organization) do
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,  "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site).tap do |org|
          benefit_sponsorship = org.employer_profile.add_benefit_sponsorship
          benefit_sponsorship.save
          org
        end
      end
      let(:person) do
        FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryBot.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:user) do
        FactoryBot.create(:user, person: person)
      end
      let(:benefit_sponsorship) do
        employer_organization.benefit_sponsorships.first
      end

      it "renders force_publish" do
        sign_in(user)
        @params = {id: benefit_sponsorship.id.to_s, employer_actions_id: "employer_actions_#{employer_organization.employer_profile.id.to_s}", :format => 'js'}
        post :force_publish, params: @params, xhr: true
        expect(response).to render_template('force_publish')
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "CSR redirection from Show" do
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :has_csr_role? => true, :last_portal_visited => nil)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_csr_role?).and_return(true)
      allow(user).to receive(:last_portal_visited=).with("http://test.host/exchanges/hbx_profiles")
      allow(user).to receive(:save)
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
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      expect(controller).to receive(:find_hbx_profile)
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
    let(:permission) { double("permission", name: "hbx_staff", view_the_configuration_tab: false )}


    before :each do
      allow(hbx_staff_role).to receive(:view_the_configuration_tab).and_return(true)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:permission).and_return(permission)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(hbx_staff_role).to receive(:permission).and_return(permission)
      allow(hbx_staff_role).to receive(:subrole).and_return(permission.name)

      allow(hbx_staff_role).to receive(:subrole).and_return(permission.name)

      allow(permission).to receive(:name).and_return(permission.name)
      sign_in(user)
      get :configuration
    end

    it "should render the configuration partial" do
      expect(response).to have_http_status(:redirect)
      expect(response).to_not render_template(:partial => 'exchanges/hbx_profiles/_configuration_index')
    end
  end

  describe "POST" do
    let(:user) { FactoryBot.create(:user)}
    let(:person) { FactoryBot.create(:person, user: user) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person) }
    let(:time_keeper_form) { instance_double(Forms::TimeKeeper) }

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)
    end

    it "sends timekeeper a date" do
      timekeeper_form_params = { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true, can_submit_time_travel_request: false, name: "hbx_staff", view_the_configuration_tab: false))

      allow(Forms::TimeKeeper).to receive(:new).with(timekeeper_form_params).and_return(time_keeper_form)
      allow(time_keeper_form).to receive(:forms_date_of_record).and_return(TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      sign_in(user)
      post :set_date, params: {forms_time_keeper: { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }}
      expect(response).to have_http_status(:redirect)
    end

    it "sends timekeeper a date and fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false, can_submit_time_travel_request: false, name: "hbx_staff", view_the_configuration_tab: false))
      sign_in(user)
      expect(TimeKeeper).not_to receive(:set_date_of_record).with( TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      post :set_date, params: {forms_time_keeper: { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }}
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end

    it "update setting" do
      Setting.individual_market_monthly_enrollment_due_on
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)

      post :update_setting, params: {setting: {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 15}}
      expect(response).to have_http_status(:redirect)
      expect(Setting.individual_market_monthly_enrollment_due_on).to eq 15
    end

    it "update setting fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false))
      sign_in(user)
      post :update_setting, params: {setting: {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 19}}
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end
  end

  describe "GET edit_dob_ssn" do

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryBot.create(:hbx_profile)}
    let(:permission_yes) { FactoryBot.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryBot.create(:permission, :can_update_ssn => false)}

    it "should return authorization error for Non-Admin users" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      get :edit_dob_ssn, params: @params,xhr: true
      expect(response).to have_http_status(:success)
    end

    it "should render the edit_dob_ssn partial for logged in users with an admin role" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      get :edit_dob_ssn, params: @params, xhr: true
      expect(response).to have_http_status(:success)
    end

  end

  describe 'GET new_eligibility' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:user) { double("user", person: person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person) }
    let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
    let(:permission_yes) { FactoryBot.create(:permission, can_add_pdc: true) }
    let(:params) do
      { person_id: person.id,
         family_actions_id: "family_actions_#{person.primary_family.id.to_s}",
         format: 'js'
       }
    end

    it "should render the new_eligibility partial" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      get :new_eligibility, params: params, xhr: true, format: :js

      expect(response).to have_http_status(:success)
      expect(response).to render_template('new_eligibility')
    end

    context 'when can_add_pdc permission is not given' do
      it 'should not render the new_eligibility partial' do
        sign_in(user)
        get :new_eligibility, params: params, xhr: true, format: :js

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST create_eligibility' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:user) { double("user", person: person, :has_hbx_staff_role? => true) }
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
    let(:max_aptc) { 12 }
    let(:csr) { 100 }
    let(:reason) { 'Test reason' }
    let(:params) do
      { person: {
          person_id: person.id,
          family_actions_id: "family_actions_#{person.primary_family.id.to_s}",
          max_aptc: max_aptc,
          csr: csr,
          effective_date: "2018-04-13",
          family_members: {
            "#{person.primary_family.active_family_members.first.person.hbx_id}" => {
              pdc_type: "is_medicaid_chip_eligible",
              reason: reason
            }
          },
          "jq_datepicker_ignore_person" => { "effective_date" => "04/13/2018" },
          format: 'js'
        }
      }
    end

    it "should render create_eligibility if save successful" do
      sign_in(user)
      get :create_eligibility, params: params, xhr: true, format: :js
      active_household = person.primary_family.active_household
      latest_active_thh = active_household.reload.latest_active_thh
      eligibility_deter = latest_active_thh.eligibility_determinations.first
      tax_household_member = latest_active_thh.tax_household_members.first

      expect(response).to have_http_status(:success)
      expect(eligibility_deter.max_aptc.to_f).to eq(max_aptc.to_f)
      expect(eligibility_deter.csr_percent_as_integer).to eq(csr)
      expect(tax_household_member.is_medicaid_chip_eligible).to be_truthy
      expect(tax_household_member.is_ia_eligible).to be_falsy
      expect(tax_household_member.reason).to eq(reason)
    end
  end


  describe "POST update_dob_ssn", :dbclean => :after_each do
    render_views

    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:person1) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:family1) {FactoryBot.create(:family, :with_primary_family_member, person: person1) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryBot.create(:hbx_profile)}
    let(:permission_yes) { FactoryBot.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryBot.create(:permission, :can_update_ssn => false)}
    let(:invalid_ssn) { "234-45-839" }
    let(:valid_ssn) { "234-45-8390" }
    let(:valid_dob) { "03/17/1987" }
    let(:valid_dob2) {'1987-03-17'}
    let(:employer_profile) { abc_profile }
    let(:organization) { abc_organization }
    let(:hired_on) {TimeKeeper.date_of_record.beginning_of_month}

    let!(:census_employees) {
      FactoryBot.create :benefit_sponsors_census_employee, :owner, employer_profile: employer_profile, benefit_sponsorship: organization.active_benefit_sponsorship
      FactoryBot.create :benefit_sponsors_census_employee, employer_profile: employer_profile, hired_on: hired_on, benefit_sponsorship: organization.active_benefit_sponsorship
    }

    let(:ce) {employer_profile.census_employees.non_business_owner.first}

    let(:employee_role) {
      employee_person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name, ssn: valid_ssn, no_ssn: false)
      FactoryBot.create(:benefit_sponsors_employee_role, person: employee_person, census_employee: ce, employer_profile: employer_profile)
    }


    before do
      allow(employee_role.census_employee).to receive(:employer_profile).and_return(abc_profile)
      allow(person).to receive(:employee_roles).and_return([employee_role])
    end

    it "should render back to edit_enrollment if there is a validation error on save" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:person => {:pid => person.id, :ssn => invalid_ssn, :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(response).to render_template('edit_enrollment')
    end

    it "should render update_enrollment if the save is successful" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      allow(person).to receive(:primary_family).and_return family
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => person.id, :ssn => valid_ssn, :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(response).to render_template('update_enrollment')
    end

    it "should set instance variable info changed if consumer role exists" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => person.id, :ssn => valid_ssn, :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(assigns(:info_changed)). to eq true
    end

    it "should set instance variable dc_status if consumer role exists" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => person.id, :ssn => valid_ssn, :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(assigns(:dc_status)). to eq false
    end

    it "should render update enrollment if the save is successful" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      allow(person1).to receive(:primary_family).and_return family1
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => person1.id, :ssn => "", :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(response).to render_template('update_enrollment')
    end

    it "should return authorization error for Non-Admin users" do
      allow(user).to receive(:has_hbx_staff_role?).and_return false
      sign_in(user)
      get :update_dob_ssn, xhr: true
      expect(response).not_to have_http_status(:success)
    end


    it "should set instance variable dont_update_ssn to true if employer has ssn/tin functionality enabled" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => employee_role.person.id, :ssn => "", :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(assigns(:dont_update_ssn)). to eq true
    end

    it "cannot update ssn for employee if employer has ssn/tin functionality enabled" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => employee_role.person.id, :ssn => "", :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(response).to render_template("update_enrollment")
      expect(response.body).to have_content((/SSN cannot be removed from this person as they are linked to at least one employer roster that requires and SSN/))
    end

    it "should set instance variable dont_update_ssn to nil if employer has ssn/tin functionality disabled" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      employer_profile.active_benefit_sponsorship.update_attributes!(is_no_ssn_enabled: true)
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => employee_role.person.id, :ssn => "", :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(assigns(:dont_update_ssn)). to eq nil
    end

    it "can update ssn for employee if employer has ssn/tin functionality disabled" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      employer_profile.active_benefit_sponsorship.update_attributes!(is_no_ssn_enabled: true)
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person => {:pid => employee_role.person.id, :ssn => "", :dob => valid_dob2}, :jq_datepicker_ignore_person => {:dob => valid_dob}, :format => 'js'}
      get :update_dob_ssn, xhr:  true, params:  @params
      expect(response).to render_template("update_enrollment")
      expect(response.body).to have_content(("DOB / SSN Update Successful"))
    end

  end

  describe "GET general_agency_index" do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    context "when GA is enabled in settings" do
      before do
        allow(Settings.aca).to receive(:general_agency_enabled).and_return(true)
        Enroll::Application.reload_routes!
      end
      it "should returns http success" do
        get :general_agency_index, format: :html, xhr: true
        expect(response).to have_http_status(:success)
      end

      it "should get general_agencies" do
        get :general_agency_index, format: :html, xhr: true
        expect(assigns(:general_agency_profiles)).to eq Kaminari.paginate_array(GeneralAgencyProfile.filter_by())
      end
    end

    context "when GA is disabled in settings" do
      before do
        allow(Settings.aca).to receive(:general_agency_enabled).and_return(false)
        Enroll::Application.reload_routes!
      end
      it "should returns http success" do
        expect(:get => :general_agency_index).not_to be_routable
      end
    end
  end

  describe "POST reinstate_enrollment", :dbclean => :around_each do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                        aasm_state: 'coverage_termination_pending'
      )}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should redirect to root path" do
      post :reinstate_enrollment, params: {enrollment_id: enrollment.id}, format: :js, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
    end
  end

  describe "POST view_enrollment_to_update_end_date", :dbclean => :around_each do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:primary) { family.primary_family_member }
    let(:dependents) { family.dependents }
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:effective_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let(:hbx_en_member1) { FactoryBot.build(:hbx_enrollment_member,
                                              eligibility_date: effective_on,
                                              coverage_start_on: effective_on,
                                              applicant_id: dependents.first.id) }
    let(:hbx_en_member2) { FactoryBot.build(:hbx_enrollment_member,
                                          eligibility_date: effective_on + 2.months,
                                          coverage_start_on: effective_on + 2.months,
                                          applicant_id: dependents.first.id) }
    let(:hbx_en_member3) { FactoryBot.build(:hbx_enrollment_member,
                                      eligibility_date: effective_on + 6.months,
                                      coverage_start_on: effective_on + 6.months,
                                      applicant_id: dependents.last.id) }
    let!(:enrollment1) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         product: product,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: effective_on,
                         terminated_on: effective_on.next_month.end_of_month,
                         kind: 'individual',
                         hbx_enrollment_members: [hbx_en_member1],
                         aasm_state: 'coverage_terminated'
      )}
    let!(:enrollment2) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         product: product,
                         kind: 'individual',
                         household: family.active_household,
                         coverage_kind: "health",
                         hbx_enrollment_members: [hbx_en_member2],
                         effective_on: effective_on + 2.months,
                         terminated_on: (effective_on + 5.months).end_of_month,
                         aasm_state: 'coverage_terminated'
      )}
    let!(:enrollment3) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         product: product,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: effective_on + 6.months,
                         terminated_on: effective_on.end_of_year,
                         kind: 'individual',
                         hbx_enrollment_members: [hbx_en_member3],
                         aasm_state: 'coverage_terminated'
      )}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should render template" do
      post :view_enrollment_to_update_end_date, params: {person_id: person.id.to_s, family_actions_id: family.id}, format: :js, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template("view_enrollment_to_update_end_date")
    end

    it "should get duplicate enrollment id's" do
      post :view_enrollment_to_update_end_date, params: {person_id: person.id.to_s, family_actions_id: family.id}, format: :js, xhr: true
      expect(assigns(:dup_enr_ids).include?(enrollment1.id.to_s)).to eq true
      expect(assigns(:dup_enr_ids).include?(enrollment3.id.to_s)).to eq false
    end
  end

  describe "POST update_terminate_enrollment", :dbclean => :around_each do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family,
        household: family.active_household,
        coverage_kind: "health",
        kind: 'employer_sponsored',
        effective_on: ::TimeKeeper.date_of_record.last_month.beginning_of_month,
        aasm_state: 'coverage_selected'
      )
    end

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    shared_examples_for "POST update_terminate_enrollment" do |aasm_state, terminated_date|
      context 'shop enrollment' do
        it 'should render template' do
          post :update_terminate_enrollment, params: { "termination_date_#{enrollment.id}".to_sym => terminated_date, "terminate_hbx_#{enrollment.id}".to_sym => enrollment.id.to_s }, format: :js, xhr: true
          expect(response).to have_http_status(:success)
        end
      end

      it "enrollment should be moved to #{aasm_state}" do
        post :update_terminate_enrollment, params: { "termination_date_#{enrollment.id}".to_sym => terminated_date, "terminate_hbx_#{enrollment.id}".to_sym => enrollment.id.to_s }, format: :js, xhr: true
        enrollment.reload
        expect(enrollment.aasm_state).to eq aasm_state
        expect(enrollment.terminated_on).to eq Date.strptime(terminated_date, "%m/%d/%Y")
      end
    end

    it_behaves_like 'POST update_terminate_enrollment', 'coverage_termination_pending', ::TimeKeeper.date_of_record.next_month.beginning_of_month.to_s
    it_behaves_like 'POST update_terminate_enrollment', 'coverage_terminated', ::TimeKeeper.date_of_record.prev_day.to_s
  end

  describe "POST update_enrollment_termianted_on_date", :dbclean => :around_each do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:original_termination_date) { TimeKeeper.date_of_record.next_month.end_of_month }
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         household: family.active_household,
                         coverage_kind: "health",
                         kind: 'employer_sponsored',
                         effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                         terminated_on: original_termination_date,
                         aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }


    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    context "shop enrollment" do
      context "with valid params" do
        it "should render template " do
          post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s}, format: :js, xhr: true
          expect(response).to have_http_status(:success)
          expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
        end

        context "enrollment that already terminated with past date" do
          context "with new past or current termination date" do
            let(:terminated_date) { original_termination_date - 1.day }
            let(:original_termination_date) { TimeKeeper.date_of_record.beginning_of_month }

            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: terminated_date}, format: :js, xhr: true
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq terminated_date
            end
          end

        end

        context "enrollment that already terminated with future date" do
          context "with new future termination date" do
            let(:terminated_date) { original_termination_date - 1.day }

            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: terminated_date.to_s}, format: :js, xhr: true
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_termination_pending"
              expect(enrollment.terminated_on).to eq(terminated_date)
            end
          end
        end
      end
    end

    context "IVL enrollment", :dbclean => :around_each do

      before do
        enrollment.kind = "individual"
        enrollment.save
      end

      context "with valid params" do

        it "should render template " do
          post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s}, format: :js, xhr: true
          expect(response).to have_http_status(:success)
          expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
        end

        context "enrollment that already terminated with past date" do
          context "with new past or current termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s}, format: :js, xhr: true
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record
            end
          end

        end

        context "enrollment that already terminated with future date" do
          context "with new future termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              post :update_enrollment_termianted_on_date, params: {enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: (TimeKeeper.date_of_record + 1.day).to_s}, format: :js, xhr: true
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
            end
          end
        end
      end
    end

    context "with invalid params" do
      it "should redirect to root path" do
        post :update_enrollment_termianted_on_date, params: {enrollment_id: '', family_actions_id: '', new_termination_date: ''}, format: :js, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
      end
    end

  end

  describe "GET get_user_info" do
    let(:user) { double("User", :has_hbx_staff_role? => true)}
    let(:person) { double("Person", id: double)}
    let(:family_id) { double("Family_ID")}
    let(:employer_id) { "employer_id_1234" }
    let(:organization) { double("Organization")}
    let(:employer_profile) { double }

    before do
      sign_in user
      allow(Person).to receive(:find).with("#{person.id}").and_return person
      allow( BenefitSponsors::Organizations::Profile).to receive(:find).with(
        "1234"
      ).and_return(employer_profile)
      allow(employer_profile).to receive(:organization).and_return(organization)
    end

    context "when action called through families datatable" do

      before do
        get :get_user_info, params: {family_actions_id: family_id, person_id: person.id}, xhr: true
      end

      it "should populate the person instance variable" do
        expect(assigns(:person)).to eq person
      end

      it "should populate the row id to instance variable" do
        expect(assigns(:element_to_replace_id)).to eq "#{family_id}"
      end
    end

    context "when action called through employers datatable" do

      before do
        allow( BenefitSponsors::Organizations::Profile).to receive(:find).with(
          "1234"
        ).and_return(employer_profile)
        allow(employer_profile).to receive(:organization).and_return(organization)
        get :get_user_info, params: {employer_actions_id: employer_id, people_id: [person.id]}, xhr: true
      end

      it "should not populate the person instance variable" do
        expect(assigns(:person)).to eq nil
      end

      it "should populate the people instance variable" do
        expect(assigns(:people).class).to eq Mongoid::Criteria
      end

      it "should populate the employer_actions instance variable" do
        expect(assigns(:employer_actions)).to eq true
      end

      it "should populate the row id to instance variable" do
        expect(assigns(:element_to_replace_id)).to eq "#{employer_id}"
      end
    end
  end

  describe "extend open enrollment" do

    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:permission) { double(can_extend_open_enrollment: true) }
    let(:hbx_staff_role) { double("hbx_staff_role", permission: permission)}
    let(:hbx_profile) { double("HbxProfile")}
    let(:benefit_sponsorship) { double(benefit_applications: benefit_applications) }
    let(:benefit_applications) { [ double ]}

    before :each do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(::BenefitSponsors::BenefitSponsorships::BenefitSponsorship).to receive(:find).and_return(benefit_sponsorship)
      sign_in(user)
    end

    context '.oe_extendable_applications' do
      let(:benefit_applications) { [ double(may_extend_open_enrollment?: true) ]}

      before do
        allow(benefit_sponsorship).to receive(:oe_extendable_benefit_applications).and_return(benefit_applications)
      end

      it "renders open enrollment extendable applications" do
        get :oe_extendable_applications, xhr: true

        expect(response).to have_http_status(:success)
        expect(response).to render_template("exchanges/hbx_profiles/oe_extendable_applications")
      end
    end

    context '.oe_extended_applications' do
      let(:benefit_applications) { [ double(enrollment_extended?: true) ]}

      before do
        allow(benefit_sponsorship).to receive(:oe_extended_applications).and_return(benefit_applications)
      end

      it "renders open enrollment extended applications" do
        get :oe_extended_applications, xhr: true

        expect(response).to have_http_status(:success)
        expect(response).to render_template("exchanges/hbx_profiles/oe_extended_applications")
      end
    end

    context '.edit_open_enrollment' do
      let(:benefit_application) { double }

      before do
        allow(benefit_applications).to receive(:find).and_return(benefit_application)
      end

      it "renders edit open enrollment" do
        get :edit_open_enrollment, xhr: true

        expect(response).to have_http_status(:success)
        expect(response).to render_template("exchanges/hbx_profiles/edit_open_enrollment")
      end
    end

    context '.extend_open_enrollment' do
      let(:benefit_application) { double }

      before do
        allow(benefit_applications).to receive(:find).and_return(benefit_application)
        allow(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive_message_chain(:new,:extend_open_enrollment).and_return(true)
      end

      it "renders index" do
        post :extend_open_enrollment, params: {open_enrollment_end_date: "11/26/2018"}

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
      end
    end
  end

  describe "close open enrollment", :dbclean => :around_each do

    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:permission) { double(can_extend_open_enrollment: true) }
    let(:hbx_staff_role) { double("hbx_staff_role", permission: permission)}
    let(:hbx_profile) { double("HbxProfile")}
    let(:benefit_sponsorship) { double(benefit_applications: benefit_applications) }
    let(:benefit_applications) { [ double ]}

    before :each do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(::BenefitSponsors::BenefitSponsorships::BenefitSponsorship).to receive(:find).and_return(benefit_sponsorship)
      sign_in(user)
    end

    context '.close_extended_open_enrollment' do
      let(:benefit_application) { double }

      before do
        allow(benefit_applications).to receive(:find).and_return(benefit_application)
        allow(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive_message_chain(:new,:end_open_enrollment).and_return(true)
      end

      it "renders index" do
        post :close_extended_open_enrollment

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
      end
    end
  end

  describe "benefit application creation", :dbclean => :around_each do
    let!(:user)                { FactoryBot.create(:user) }
    let!(:person)              { FactoryBot.create(:person, user: user) }
    let!(:permission)          { FactoryBot.create(:permission, :super_admin) }
    let!(:hbx_staff_role)      { FactoryBot.create(:hbx_staff_role, person: person, permission_id: permission.id, subrole:permission.name) }
    let!(:rating_area)         { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)        { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
    let!(:benefit_market)      { site.benefit_markets.first }
    let!(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization,  "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
    let!(:employer_profile)    { organization.employer_profile }
    let!(:benefit_sponsorship) { bs = employer_profile.add_benefit_sponsorship
                                bs.save!
                                bs
                               }
    let(:effective_period)     { (TimeKeeper.date_of_record + 3.months)..(TimeKeeper.date_of_record + 1.year + 3.months - 1.day) }
    let!(:current_benefit_market_catalog) do
      BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
      benefit_market.benefit_market_catalogs.where(
        "application_period.min" => effective_period.min.to_s
      ).first
    end

    let!(:valid_params)   {
      { admin_datatable_action: true,
        benefit_sponsorship_id: benefit_sponsorship.id.to_s,
        start_on: effective_period.min,
        end_on: effective_period.max,
        open_enrollment_start_on: TimeKeeper.date_of_record + 2.months,
        open_enrollment_end_on: TimeKeeper.date_of_record + 2.months + 20.day
      }
    }

    before :each do
      sign_in(user)
    end

    context 'viewing configuration tab' do
      before :each do
        get :configuration
      end

      it 'should respond with success status' do
        expect(response).to have_http_status(:success)
      end
    end

    context '.new_benefit_application' do
      before :each do
        get :new_benefit_application, params: {benefit_sponsorship_id: benefit_sponsorship.id.to_s}, xhr: true
      end

      it 'should respond with success status' do
        expect(response).to have_http_status(:success)
      end

      it 'should render new_benefit_application' do
        expect(response).to render_template("exchanges/hbx_profiles/new_benefit_application")
      end
    end

    context '.create_benefit_application when existing draft application' do
      before :each do
        post :create_benefit_application, params: valid_params.merge({has_active_ba: false}), xhr: true
      end

      it 'should respond with success status' do
        expect(response).to have_http_status(:success)
      end

      it 'should render new_benefit_application' do
        expect(response).to render_template("exchanges/hbx_profiles/create_benefit_application")
      end
    end

    context '.create_benefit_application when existing application is in active states' do
      before :each do
        post :create_benefit_application, params: valid_params.merge({has_active_ba: true}), xhr: true
      end

      it 'should respond with success status' do
        expect(response).to have_http_status(:success)
      end

      it 'should render new_benefit_application' do
        expect(response).to render_template("exchanges/hbx_profiles/create_benefit_application")
      end
    end
  end

  describe "GET edit_fein", :dbclean => :around_each do

    context "of an hbx super admin clicks Change FEIN" do
      let(:site) do
        FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
      end
      let(:employer_organization) do
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,  "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site).tap do |org|
          benefit_sponsorship = org.employer_profile.add_benefit_sponsorship
          benefit_sponsorship.save
          org
        end
      end
      let(:person) do
        FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryBot.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:user) do
        FactoryBot.create(:user, person: person)
      end
      let(:benefit_sponsorship) do
        employer_organization.benefit_sponsorships.first
      end

      it "renders edit_fein" do
        sign_in(user)
        @params = {id: benefit_sponsorship.id.to_s, employer_actions_id: "employer_actions_#{employer_organization.employer_profile.id.to_s}", :format => 'js'}
        get :edit_fein, params: @params, xhr: true
        expect(response).to render_template('edit_fein')
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST update_fein", :dbclean => :around_each do

    context "of an hbx super admin clicks Submit in Change FEIN window" do
      let(:site) do
        FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key)
      end
      let(:employer_organization) do
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,  "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site).tap do |org|
          benefit_sponsorship = org.employer_profile.add_benefit_sponsorship
          benefit_sponsorship.save
          org
        end
      end
      let(:person) do
        FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryBot.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:user) do
        FactoryBot.create(:user, person: person)
      end
      let(:benefit_sponsorship) do
        employer_organization.benefit_sponsorships.first
      end

      let(:new_valid_fein) { "23-4508390" }

      it "renders update_fein" do
        sign_in(user)
        @params = {:organizations_general_organization => {:new_fein => new_valid_fein}, :id => benefit_sponsorship.id.to_s, :employer_actions_id => "employer_actions_#{employer_organization.employer_profile.id.to_s}"}
        post :update_fein, params: @params, xhr: true
        expect(response).to render_template('update_fein')
        expect(response).to have_http_status(:success)
      end
    end
  end
end
