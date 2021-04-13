require 'rails_helper'
require File.expand_path(
  File.join(
    File.dirname(__FILE__),
    "../../..",
    "components/benefit_sponsors/spec/support/benefit_sponsors_site_spec_helpers"
  )
)
require File.expand_path(
  File.join(
    File.dirname(__FILE__),
    "../../..",
    "components/benefit_sponsors/spec/support/benefit_sponsors_organization_spec_helpers"
  )
)

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe GeneralAgencies::ProfilesController, dbclean: :after_each do
  let(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile }

  let(:benefit_sponsors_general_agency_profile) do
    org_id = BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_general_agency_profile(site)
    org = BenefitSponsors::Organizations::Organization.find(org_id)
    org.general_agency_profile
  end

  let(:general_agency_profile) { FactoryBot.create(:general_agency_profile) }
  let(:general_agency_staff) do
    FactoryBot.create(
      :general_agency_staff_role,
      benefit_sponsors_general_agency_profile_id: benefit_sponsors_general_agency_profile.id
    )
  end
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }

  before :each do
    general_agency_staff
    allow(Settings.aca).to receive(:general_agency_enabled).and_return(true)
    Enroll::Application.reload_routes!
  end

  describe "GET new" do
    it "should redirect to new model" do
      get :new
      expect(response).to have_http_status(:redirect)
    end

    it "should render the new template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_new).and_return true
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET index" do
    it "should redirect without login" do
      get :index
      expect(response).to have_http_status(:redirect)
    end

    it "should render the index template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_index).and_return true
      sign_in(user)
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe "patch update" do
    let(:user) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff"]) }
    let(:person) { FactoryBot.create(:person, :with_general_agency_staff_role) }
    let(:general_agency_staff) { person.general_agency_staff_roles.last }
    let(:org) { GeneralAgencyProfile.find( person.general_agency_staff_roles.first.general_agency_profile_id).organization}
    let(:general_agency_staff_role) { person.general_agency_staff_roles.first }
    let(:general_agency_profile){ GeneralAgencyProfile.find( person.general_agency_staff_roles.first.general_agency_profile_id) }
    before :each do
      sign_in user
      allow(controller).to receive(:sanitize_agency_profile_params).and_return(true)
      allow(controller).to receive(:authorize).and_return(true)
    end

    it "should update person main phone" do
      general_agency_profile.primary_staff.person.phones[0].update_attributes(kind: "work")
      post :update, params:{id: general_agency_profile.id, organization: {id: org.id, first_name: "updated name", last_name: "updates", office_locations_attributes: {"0"=>
                                                                                                                                                               {"address_attributes"=>{"kind"=>"primary", "address_1"=>"234 nfgjkhghf", "address_2"=>"", "city"=>"jfhgdfhgjgdf", "state"=>"DC", "zip"=>"35645"},
                                                                                                                                                                "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"564", "number"=>"111-1111", "extension"=>"111"}}}}}
      general_agency_profile.primary_staff.person.reload
      expect(general_agency_profile.primary_staff.person.phones[0].extension).to eq "111"
    end

    it "should update person record" do
      post :update, params:{id: general_agency_profile.id, organization: {id: org.id, first_name: "updated name", last_name: "updates", office_locations_attributes: {"0"=>
                                                                                                                                                               {"address_attributes"=>{"kind"=>"primary", "address_1"=>"234 nfgjkhghf", "address_2"=>"", "city"=>"jfhgdfhgjgdf", "state"=>"DC", "zip"=>"35645"},
                                                                                                                                                                "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"564", "number"=>"111-1111", "extension"=>"111"}}}}}
      general_agency_profile.primary_staff.person.reload
      expect(general_agency_profile.primary_staff.person.first_name).to eq "updated name"
    end
  end

  describe "GET new_agency" do
    it "should redirect to new model" do
      get :new_agency_staff
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET new_agency_staff" do
    it "should redirect to new model" do
      get :new_agency_staff
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET search_general_agency" do
    it "should returns http success" do
      get :search_general_agency, params:{general_agency_search: 'general_agency'}, xhr: true, format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get general_agency_profile" do
      Organization.delete_all
      ga = FactoryBot.create(:general_agency_profile)
      get :search_general_agency, params:{general_agency_search: ga.legal_name}, xhr: true, format: :js
      expect(assigns[:general_agency_profiles]).to eq [ga]
    end
  end

  describe "GET show" do
    before(:each) do
      FactoryBot.create(:announcement, content: "msg for GA", audiences: ['GA'])
      allow(user).to receive(:has_general_agency_staff_role?).and_return true
      sign_in(user)
      get :show, params:{id: general_agency_profile.id}
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end

    it "should get provider" do
      expect(assigns[:provider]).to eq person
    end

    it "should get staff_role" do
      expect(assigns[:staff_role]).to eq user.has_general_agency_staff_role?
    end

    it "should get announcement" do
      expect(flash.now[:warning]).to eq ["msg for GA"]
    end
  end

  describe "GET employers" do
    before(:each) do
      sign_in(user)
      get :employers, params:{id: general_agency_profile.id}, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the employers template" do
      expect(response).to render_template("employers")
    end

    it "should get employers" do
      #expect(assigns[:employers]).to eq general_agency_profile.employer_clients
    end
  end

  describe "GET families" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    before(:each) do
      allow(GeneralAgencyProfile).to receive(:find).and_return(general_agency_profile)
      allow(general_agency_profile).to receive(:families).and_return [family]
      sign_in(user)
    end

    context "without page params" do
      let(:person2) { FactoryBot.create(:person , :last_name => "smith11") } # last name has to be in small case
      let(:family2) { FactoryBot.create(:family, :with_primary_family_member , :person => person2  ) }
      before(:each) do
        allow(general_agency_profile).to receive(:families).and_return [family,family2]
        get :families, params:{id: general_agency_profile.id}, xhr: true
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the families template" do
        expect(response).to render_template("families")
      end

      it "should get families" do
        # expect(assigns[:families]).to eq general_agency_profile.families
        # expect(assigns[:families]).to eq [family,family2]
      end

      it "should assign uniq page_alphabets" do
        #expect(assigns[:page_alphabets]).to eq ["S"]
      end
    end

    # context "with page params" do
    #   it "should get family" do
    #     page = family.primary_applicant.person.last_name.first
    #     xhr :get, :families, id: general_agency_profile.id, page: page
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq [family]
    #   end

    #   it "should get family with full_name" do
    #     full_name = family.primary_applicant.person.full_name
    #     xhr :get, :families, id: general_agency_profile.id, q: full_name
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq [family]
    #   end

    #   it "should not get family" do
    #     page = family.primary_applicant.person.last_name.first
    #     xhr :get, :families, id: general_agency_profile.id, page: '1'
    #     expect(page).not_to eq '1'
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq []
    #   end
    # end
  end

  describe "GET staffs" do
    before(:each) do
      sign_in(user)
      get :staffs, params:{id: general_agency_profile.id}, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the staffs template" do
      expect(response).to render_template("staffs")
    end

    it "should get staffs" do
      expect(assigns[:staffs]).to eq general_agency_profile.general_agency_staff_roles
    end
  end

  describe "GET edit_staff" do
    before(:each) do
      sign_in(user)
      get :edit_staff, params:{id: general_agency_staff.id}, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the staffs template" do
      expect(response).to render_template("edit_staff")
    end
  end

  describe "POST update_staff" do
    before(:each) do
      FactoryBot.create(:hbx_profile) if HbxProfile.count == 0
      sign_in(user)
      general_agency_staff.unset(:benefit_sponsors_general_agency_profile_id) # ToDo - Move/remove these old specs
      post :update_staff, params:{id: general_agency_staff.id, approve: 'true'}
    end

    it "should redirect" do
      expect(response).to have_http_status(:redirect)
    end

    it "should get notice" do
      expect(flash[:notice]).to eq "Staff approved successfully."
    end

    it "should change staff status" do
      general_agency_staff.reload
      expect(general_agency_staff.aasm_state).to eq 'active'
    end
  end

  describe "GET messages" do
    before(:each) do
      sign_in(user)
      get :messages, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the messages template" do
      expect(response).to render_template("messages")
    end

    it "should get provider" do
      expect(assigns(:provider)).to eq person
    end
  end

  describe "GET agency_messages" do
    before(:each) do
      sign_in(user)
      get :agency_messages, params:{id: general_agency_profile.id}, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the agency_messages template" do
      expect(response).to render_template("agency_messages")
    end
  end

  describe "GET inbox" do
    before(:each) do
      sign_in(user)
      get :inbox, params:{id: general_agency_profile.id}, xhr: true
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the inbox template" do
      expect(response).to render_template("inbox")
    end

    it "should get general_agency_profile" do
      expect(assigns(:general_agency_provider)).to eq general_agency_profile
    end

    it "should get provider" do
      expect(assigns(:provider)).to eq general_agency_profile
    end
  end

  describe "POST create" do
    before do
      sign_in(user)
    end

    it "should redirect" do
      post :create, params:{organization: {first_name: 'test'}}
      expect(response).to have_http_status(:redirect)
    end
  end
end
end