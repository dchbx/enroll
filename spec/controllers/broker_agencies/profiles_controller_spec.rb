require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesController do
  let(:broker_agency_profile_id) { "abecreded" }
  let!(:broker_agency) { FactoryGirl.create(:broker_agency) }
  let(:broker_agency_profile) { broker_agency.broker_agency_profile }

  describe "GET new" do
    let(:user) { FactoryGirl.create(:user) }
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:last_portal_visited).and_return 'test.com'
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_role?).and_return(false)
      allow(user).to receive(:last_portal_visited=).and_return("true")
      allow(user).to receive(:save).and_return(true)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:person) { FactoryGirl.create(:person) }

    before(:each) do
      FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile, person: person)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(true)
      FactoryGirl.create(:announcement, content: "msg for Broker", audiences: ['Broker'])
      sign_in(user)
      get :show, id: broker_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end

    it "should get announcement" do
      expect(flash.now[:warning]).to eq ["msg for Broker"]
    end
  end

  describe "GET edit" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:person) { FactoryGirl.create(:person) }
    before :each do
      FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile, person: person)
      sign_in user
      get :edit, id: broker_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the edit template" do
      expect(response).to render_template("edit")
    end
  end

  describe "patch update" do
    let(:user) { double(has_broker_role?: true)}
    #let(:org) { double }
    let(:org) { FactoryGirl.create(:organization)}
    let(:broker_agency_profile){ FactoryGirl.create(:broker_agency_profile, organization: org) }
    let(:organization_params) do
      {
        id: org.id, first_name: "updated name", last_name: "updates", accept_new_clients: true, working_hours: true,
        office_locations_attributes: {
          "0"=> {
            "address_attributes" => {"kind"=>"primary", "address_1"=>"234 nfgjkhghf", "address_2"=>"", "city"=>"jfhgdfhgjgdf", "state"=>"DC", "zip"=>"35645"},
            "phone_attributes"=> {"kind"=>"phone main", "area_code"=>"564", "number"=>"111-1111", "extension"=>"111"}
          }
        }
      }
    end
    before :each do
      sign_in user
      #allow(Forms::BrokerAgencyProfile).to receive(:find).and_return(org)
      allow(controller).to receive(:sanitize_broker_profile_params).and_return(true)
      allow(controller).to receive(:authorize).and_return(true)
    end

    it "should update person main phone" do
      broker_agency_profile.primary_broker_role.person.phones[0].update_attributes(kind: "phone main")
      post :update, id: broker_agency_profile.id, organization: organization_params
       broker_agency_profile.primary_broker_role.person.reload
       expect(broker_agency_profile.primary_broker_role.person.phones[0].extension).to eq "111"
    end

    it "should update person record" do
      post :update, id: broker_agency_profile.id, organization: organization_params
      broker_agency_profile.primary_broker_role.person.reload
      expect(broker_agency_profile.primary_broker_role.person.first_name).to eq "updated name"
    end

    it "should update record without a phone extension" do
      post :update, id: broker_agency_profile.id, organization: organization_params
      broker_agency_profile.primary_broker_role.person.reload
      expect(broker_agency_profile.primary_broker_role.person.first_name).to eq "updated name"
    end

    it "should update record by saving accept new clients" do
      post :update, id: broker_agency_profile.id, organization: organization_params
      broker_agency_profile.reload
      expect(broker_agency_profile.accept_new_clients).to be_truthy
      expect(broker_agency_profile.working_hours).to be_truthy
    end
  end

  describe "GET index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_broker_agency_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_broker_role?).and_return(false)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :index
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end
  end

  describe "CREATE post" do
    let(:user){ double(:save => double("user")) }
    let(:person){ double(:broker_agency_contact => double("test")) }
    let(:broker_agency_profile){ double("test") }
    let(:form){double("test", :broker_agency_profile => broker_agency_profile)}
    let(:organization) {double("organization")}
    context "when no broker role" do
      before(:each) do
        allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
        allow(user).to receive(:has_broker_role?).and_return(false)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return(person)
        sign_in(user)
        allow(Forms::BrokerAgencyProfile).to receive(:new).and_return(form)
      end

      it "returns http status" do
        allow(form).to receive(:save).and_return(true)
        post :create, organization: {}
        expect(response).to have_http_status(:redirect)
      end

      it "should render new template when invalid params" do
        allow(form).to receive(:save).and_return(false)
        post :create, organization: {}
        expect(response).to render_template("new")
      end
    end

  end

  describe "REDIRECT to my account if broker role present" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}
    let(:person){double(:broker_agency_staff_roles => [double(:broker_agency_profile_id => 5)]) }

    it "should redirect to myaccount" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "get employers" do
    let(:user) { FactoryGirl.create(:user, :roles => ['broker_agency_staff'], :person => person)}
    let(:user1) {FactoryGirl.create(:user,:roles=> [], person: broker_role.person)}
    let(:person) {broker_agency_staff_role.person}
    let(:person1) {broker_role.person}
    let(:organization) {FactoryGirl.create(:organization)}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
    let(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile)}
    let(:broker_role) { FactoryGirl.create(:broker_role,  broker_agency_profile: broker_agency_profile, aasm_state: 'active')}
    it "should get organizations for employers where broker_agency_account is active" do
      allow(person).to receive(:broker_role).and_return(nil)
      allow(person).to receive(:hbx_staff_role).and_return(nil)
      sign_in user
      xhr :get, :employers, id: broker_agency_profile.id, format: :js
      expect(response).to have_http_status(:success)
      orgs = Organization.where({"employer_profile.broker_agency_accounts"=>{:$elemMatch=>{:is_active=>true, :broker_agency_profile_id=>broker_agency_profile.id}}})
      expect(assigns(:orgs)).to eq orgs
    end

    it "should get organizations for employers where writing_agent is active" do
      sign_in user1
      xhr :get, :employers, id: broker_agency_profile.id, format: :js
      expect(response).to have_http_status(:success)
      orgs = Organization.where({"employer_profile.broker_agency_accounts"=>{:$elemMatch=>{:is_active=>true, :writing_agent_id=> broker_role.id }}})
      expect(assigns(:orgs)).to eq orgs
    end
  end

  describe "family_index" do
    before :all do
      org = FactoryGirl.create(:organization)
      @broker_agency_profile1 = FactoryGirl.create(:broker_agency_profile, organization: org,aasm_state:'active')
      broker_role = FactoryGirl.create(:broker_role, broker_agency_profile_id: @broker_agency_profile1.id, aasm_state:'active')
      person = broker_role.person
      @current_user = FactoryGirl.create(:user, person: person, roles: [:broker])
      families = []
      30.times.each do
        family = FactoryGirl.create(:family, :with_primary_family_member)
        family.hire_broker_agency(broker_role.id)
        families << family
      end
      families[0].primary_applicant.person.update_attributes!(last_name: 'Jones1')
      families[1].primary_applicant.person.update_attributes!(last_name: 'Jones2')
      families[2].primary_applicant.person.update_attributes!(last_name: 'jones3')
    end

    it "renders the families_index template" do
      current_user = @current_user
      allow(current_user).to receive(:has_broker_role?).and_return(true)
      sign_in current_user
      xhr :get, :family_index, id: broker_agency_profile.id
      expect(response).to render_template("broker_agencies/profiles/family_index")
    end
  end

  describe "eligible_brokers" do

    context "when individual is enabled" do
      before :each do
        stub_const("BrokerAgencyProfile::MARKET_KINDS",%W[shop individual both])
        DatabaseCleaner.clean
        org1 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
        broker_agency_profile1 = FactoryGirl.create(:broker_agency_profile, organization:org1, market_kind:'individual')
        FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile1.id, market_kind:'individual', aasm_state:'active')

        org2 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
        broker_agency_profile2 = FactoryGirl.create(:broker_agency_profile, organization:org2, market_kind:'shop')
        FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile2.id, market_kind:'shop', aasm_state:'active')

        org3 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
        broker_agency_profile3 = FactoryGirl.create(:broker_agency_profile, organization:org3, market_kind:'both')
        FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile3.id, market_kind:'both', aasm_state:'active')
      end
      context "individual market user" do
        let(:person) {FactoryGirl.build(:person, us_citizen: "false", indian_tribe_member: "false", eligible_immigration_status: "false", is_consumer_role:true)}
        let(:user) {FactoryGirl.build(:user, person: person, roles: ['consumer'])}

        it "selects only 'individual' and 'both' market brokers" do
          allow(subject).to receive(:current_user).and_return(user)
          controller.instance_variable_set(:@person, person)
          staff = subject.instance_eval{ eligible_brokers }
          staff.each do |staff_person|
           expect(["individual", "both"].include? staff_person.broker_role.market_kind).to be_truthy
          end
        end
        context "SHOP market user" do
          let(:person) {FactoryGirl.build(:person, us_citizen: "false", indian_tribe_member: "false", eligible_immigration_status: "false", is_consumer_role:true)}
          let(:user) {FactoryGirl.build(:user, person: person, roles: ['employer'])}

          it "selects only 'shop' and 'both' market brokers" do
            allow(subject).to receive(:current_user).and_return(user)
            controller.instance_variable_set(:@person, person)
            staff = subject.instance_eval{ eligible_brokers }

            staff.each do |staff_person|
              expect(["shop", "both"].include? staff_person.broker_role.market_kind).to be_truthy
            end
          end
        end
      end
    end


    context "SHOP market user" do
      let(:person) {FactoryGirl.build(:person, is_consumer_role:true)}
      let(:user) {FactoryGirl.build(:user, person: person, roles: ['employer'])}

      before :each do
        DatabaseCleaner.clean
        stub_const("BrokerAgencyProfile::MARKET_KINDS",%W[shop])

        org2 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
        broker_agency_profile2 = FactoryGirl.create(:broker_agency_profile, organization:org2, market_kind:'shop')
        FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile2.id, market_kind:'shop', aasm_state:'active')
      end
      context "SHOP market user" do
        let(:person) {FactoryGirl.build(:person, us_citizen: "false", indian_tribe_member: "false", eligible_immigration_status: "false",  is_consumer_role:true)}
        let(:user) {FactoryGirl.build(:user, person: person, roles: ['employer'])}

        it "selects only 'shop' market brokers" do
          allow(subject).to receive(:current_user).and_return(user)
          controller.instance_variable_set(:@person, person)
          staff = subject.instance_eval{ eligible_brokers }

          staff.each do |staff_person|
            expect(["shop"].include? staff_person.broker_role.market_kind).to be_truthy
          end
        end
      end
    end
  end

  describe "GET assign" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    context "when general agency is enabled via settings" do
      before :each do
        Settings.aca.general_agency_enabled = true
        sign_in user
        xhr :get, :assign, id: broker_agency_profile.id, format: :js
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end

      it "should get general_agency_profiles" do
        expect(assigns(:general_agency_profiles)).to eq GeneralAgencyProfile.all_by_broker_role(broker_role)
      end

      it "should get employers" do
        expect(assigns(:employers)).to eq Organization.by_broker_agency_profile(broker_agency_profile.id).map(&:employer_profile).first(20)
      end
    end

    context "when general agency is disabled via settings" do
      before :each do
        Settings.aca.general_agency_enabled = false
        sign_in user
        xhr :get, :assign, id: broker_agency_profile.id, format: :js
      end

      it "should return http redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should redirect to broker_agency_profile" do
        expect(response).to redirect_to(broker_agencies_profile_path(broker_agency_profile))
      end

      it "general_agency_profiles should be nil" do
        expect(assigns(:general_agency_profiles)).to be_nil
      end

      it "employers should be nil" do
        expect(assigns(:employers)).to be_nil
      end
    end
  end

  describe "GET assign_history" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:hbx) { FactoryGirl.create(:user, person: person, roles: ['hbx_staff']) }

    context "with admin user" do
      before :each do
        sign_in hbx
        xhr :get, :assign_history, id: broker_agency_profile.id, format: :js
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end

      it "should get general_agency_accounts" do
        expect(assigns(:general_agency_account_history)).to eq GeneralAgencyAccount.all.first(20)
      end
    end

    context "with broker user" do
      before :each do
        sign_in user
        xhr :get, :assign_history, id: broker_agency_profile.id, format: :js
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end

      it "should get general_agency_accounts" do
        expect(assigns(:general_agency_account_history)).to eq GeneralAgencyAccount.find_by_broker_role_id(broker_role.id).first(20)
      end
    end
  end

  describe "GET clear_assign_for_employer" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile, aasm_state: "is_approved") }
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:favorite_general_agency) { FactoryGirl.create(:favorite_general_agency, general_agency_profile_id: general_agency_profile.id, broker_role: broker_role) }
    let(:person) { broker_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, general_agency_profile: general_agency_profile) }

    before :each do
      sign_in user
      favorite_general_agency.reload
      xhr :get, :clear_assign_for_employer, id: broker_agency_profile.id, employer_id: employer_profile.id
    end

    it "should assign general agency profiles" do
      expect(assigns(:broker_role)).to eq broker_role
      expect(assigns(:general_agency_profiles)).to eq [general_agency_profile]
    end

    it "should http success" do
      expect(response).to have_http_status(:success)
    end

    it "should get employer_profile" do
      expect(assigns(:employer_profile)).to eq employer_profile
    end

  end

  describe "POST update_assign" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, general_agency_profile: general_agency_profile) }
    context "when general agency is enabled via settings" do
      before do
        Settings.aca.general_agency_enabled = true
      end
      context "when we Assign agency" do
        before :each do
          sign_in user
          xhr :post, :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], general_agency_id: general_agency_profile.id, type: 'Hire'
        end

        it "should render" do
          expect(response).to render_template(:update_assign)
        end

        it "should get notice" do
          expect(flash[:notice]).to eq 'Assign successful.'
        end
      end
      context "when we Unassign agency" do
        before :each do
          sign_in user
          post :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], commit: "Clear Assignment"
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get notice" do
          expect(flash[:notice]).to eq 'Unassign successful.'
        end
        it "should update aasm_state" do
          employer_profile.reload
          expect(employer_profile.general_agency_accounts.first.aasm_state).to eq "inactive"
        end
      end
    end

    context "when general agency is enabled via settings" do
      before do
        Settings.aca.general_agency_enabled = true
      end
      context "when we Assign agency" do
        before :each do
          sign_in user
          xhr :post, :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], general_agency_id: general_agency_profile.id, type: 'Hire'
        end

        it "should render" do
          expect(response).to render_template(:update_assign)
        end

        it "should get notice" do
          expect(flash[:notice]).to eq 'Assign successful.'
        end
      end
      context "when we Unassign agency" do
        before :each do
          sign_in user
          post :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], commit: "Clear Assignment"
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get notice" do
          expect(flash[:notice]).to eq 'Unassign successful.'
        end
        it "should update aasm_state" do
          employer_profile.reload
          expect(employer_profile.general_agency_accounts.first.aasm_state).to eq "inactive"
        end
      end
    end

    context "when general agency is disabled via settings" do
      before do
        Settings.aca.general_agency_enabled = false
      end
      context "when we Assign agency" do
        before :each do
          sign_in user
          xhr :post, :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], general_agency_id: general_agency_profile.id, type: 'Hire'
        end

        it "should return http redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to broker_agency_profile" do
          expect(response).to redirect_to(broker_agencies_profile_path(broker_agency_profile))
        end
      end
      context "when we Unassign agency" do
        before :each do
          sign_in user
          post :update_assign, id: broker_agency_profile.id, employer_ids: [employer_profile.id], commit: "Clear Assignment"
        end

        it "should return http redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to broker_agency_profile" do
          expect(response).to redirect_to(broker_agencies_profile_path(broker_agency_profile))
        end
      end
    end
  end

  describe "POST set_default_ga" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, default_general_agency_profile_id: general_agency_profile.id) }
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker']) }
    let(:organization) { FactoryGirl.create(:organization) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, general_agency_profile: general_agency_profile, organization: organization) }
    let!(:broker_agency_account) { FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile_id: broker_agency_profile.id) }

    before :each do
      allow(BrokerAgencyProfile).to receive(:find).and_return(broker_agency_profile)
    end

    it "should set default_general_agency_profile" do
      sign_in user
      xhr :post, :set_default_ga, id: broker_agency_profile.id, general_agency_profile_id: general_agency_profile.id, format: :js
      expect(assigns(:broker_agency_profile).default_general_agency_profile).to eq general_agency_profile
    end

    it "should call general_agency_hired_notice trigger " do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
      sign_in user
      xhr :post, :set_default_ga, id: broker_agency_profile.id, general_agency_profile_id: general_agency_profile.id, format: :js
      queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
        job_info[:job] == ShopNoticesNotifierJob
      end

      expect(queued_job[:args].include?('general_agency_hired_notice')).to be_truthy
      expect(queued_job[:args].include?("#{general_agency_profile.id.to_s}")).to be_truthy
      expect(queued_job[:args].third["employer_profile_id"]).to eq employer_profile.id.to_s
    end

    it "should clear default general_agency_profile" do
      broker_agency_profile.default_general_agency_profile = general_agency_profile
      broker_agency_profile.save
      expect(broker_agency_profile.default_general_agency_profile).to eq general_agency_profile

      sign_in user
      xhr :post, :set_default_ga, id: broker_agency_profile.id, type: 'clear', format: :js
      expect(assigns(:broker_agency_profile).default_general_agency_profile).to eq nil
    end

    it "should call update_ga_for_employers" do
      sign_in user
      expect(controller).to receive(:notify)
      xhr :post, :set_default_ga, id: broker_agency_profile.id, general_agency_profile_id: general_agency_profile.id, format: :js
    end

    it "should get notice" do
      sign_in user
      xhr :post, :set_default_ga, id: broker_agency_profile.id, general_agency_profile_id: general_agency_profile.id, format: :js
      expect(assigns(:notice)).to eq "Changing default general agencies may take a few minutes to update all employers."
    end
  end

  describe "GET employer_profile datatable" do
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_agency_staff_role.person }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker_agency_staff']) }
    let(:organization) {FactoryGirl.create(:organization)}
    let(:organization1) {FactoryGirl.create(:organization)}
    let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
    let(:broker_agency_staff_role) {FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile)}
    let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile1)}
    let(:broker_agency_account1) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile2)}
    let(:employer_profile1) {FactoryGirl.create(:employer_profile, organization: organization)}
    let(:employer_profile2) {FactoryGirl.create(:employer_profile, organization: organization1)}
    let(:hbx_staff_role) {FactoryGirl.create(:hbx_staff_role, person: user.person)}

    before :each do
      user.person.hbx_staff_role = hbx_staff_role
      employer_profile1.broker_agency_accounts << broker_agency_account
      employer_profile2.broker_agency_accounts << broker_agency_account1
      sign_in user
    end

    it "should search for employers in BrokerAgencies with  search string" do
      xhr :get, :employer_datatable, id: broker_agency_profile.id, :order =>{"0"=>{"column"=>"2", "dir"=>"asc"}}, search: {value: 'abcdefgh'}
      expect(assigns(:employer_profiles).count).to   eq(0)
    end

    it "should search for employers in BrokerAgencies with empty search string" do
      xhr :get, :employer_datatable, id: broker_agency_profile.id, :order =>{"0"=>{"column"=>"2", "dir"=>"asc"}}, search: {value: ''}
      expect(assigns(:employer_profiles).count).to   eq(2)
    end
  end

  describe "messages action" do
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:person) { broker_role.person }
    let(:user_broker) { FactoryGirl.create(:user, person: person, roles: ['broker']) }

    let(:person1) { FactoryGirl.create(:person)}
    let(:user_hbx) { FactoryGirl.create(:user, person: person1, roles: ['hbx_staff']) }

    it "should render the messages template and Broker sees all messages in Broker Mail tab" do
      sign_in user_broker
      get :messages, id: broker_agency_profile.primary_broker_role.person, profile_id: broker_agency_profile.id.to_s, format: :js
      expect(response).to render_template(:messages)
    end

    it "should render the messages template and Admin should see the messages in Broker Mail tab" do
      sign_in user_hbx
      get :messages, id: user_hbx.person, profile_id: broker_agency_profile.id.to_s, format: :js
      expect(response).to render_template(:messages)
    end

    it "should pass broker data to @provider if you login as Broker User" do
      sign_in user_broker
      get :messages, id: broker_agency_profile.primary_broker_role.person, profile_id: broker_agency_profile.id.to_s, format: :js
      expect(assigns(:provider)).to eq broker_agency_profile.primary_broker_role.person
    end

    it "should pass admin records to @provider if you login as Admin User" do
      sign_in user_hbx
      get :messages, id: user_hbx.person, profile_id: broker_agency_profile.id.to_s, format: :js
      expect(assigns(:provider)).to eq user_hbx.person
    end

    it "should not have broker data in @provider if you login as Admin User" do
      sign_in user_hbx
      get :messages, id: user_hbx.person, profile_id: broker_agency_profile.id.to_s, format: :js
      expect(assigns(:provider)).not_to eq broker_agency_profile.primary_broker_role.person
    end
  end
end
