require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::RegistrationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryGirl.create_default :security_question }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let(:agency_class) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm }
    # let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc, :with_benefit_market) }
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :dc) }
    let(:person) { FactoryGirl.create(:person) }
    let(:edit_user) { FactoryGirl.create(:user, :person => person)}
    let(:user) { FactoryGirl.create(:user) }
    let(:update_user) { edit_user }
    let(:benefit_sponsor_user) { user }
    let(:broker_agency_user) { nil }

    let(:phone_attributes) {
      {
        :kind => "phone main",
        :number => "8768776",
        :area_code => "876",
        :extension => "extension"
      }
    }

    let(:address_attributes) {
      {
        :kind => "primary",
        :address_1 => "address 1",
        :address_2 => "address 2",
        :city => "city",
        :state => "MA",
        :zip => "01026",
        :county =>'Berkshire'
      }
    }

    let(:office_locations_attributes) {
      {
        0 => {
          :is_primary => true,
          :address_attributes => address_attributes,
          :phone_attributes => phone_attributes
        }
      }
    }

    let(:employer_profile_attributes) {
      {
        :office_locations_attributes => office_locations_attributes,
        :contact_method => :paper_and_electronic
      }
    }

    let(:broker_profile_attributes) {
      { :ach_account_number => "1234567890",
        :ach_routing_number => "011000015",
        :ach_routing_number_confirmation => "011000015",
        :market_kind => :shop,
        :office_locations_attributes => office_locations_attributes,
        :contact_method => :paper_and_electronic
      }
    }

    let(:benefit_sponsor_organization) {
      {
        :entity_kind => :tax_exempt_organization,
        :legal_name => "uweyrtuo",
        :dba=> "uweyruoy",
        :fein => "237864678",
        :profile_attributes => employer_profile_attributes
      }
    }

    let(:broker_organization) {
      {
        :entity_kind => :s_corporation,
        :legal_name => "uweyrtuo",
        :dba=> "uweyruoy",
        :fein => "237864678",
        :profile_attributes => broker_profile_attributes
      }
    }

    let(:staff_roles_attributes) {
      { 0 =>
        {
          :first_name => "weuryit",
          :last_name => "uyiwetr",
          :dob => "11/11/1990",
          :email => "t@t.com",
          :area_code => "786",
          :number => "8768766",
          :extension => "",
          :npn => "234234123"
        }
      }
    }

    before :each do
      allow(Settings.site).to receive(:key).and_return(:dc)
    end

    shared_examples_for "initialize registration form" do |action, params, profile_type|
      before do
        user = self.send("#{profile_type}_user")
        sign_in user if user
        if params[:id].present?
          sign_in edit_user
          params[:id] = self.send(profile_type).profiles.first.id.to_s
        end

        if params.empty?
          params[:agency] = self.send("#{profile_type}_params")
        end
        get action, params
      end
      it "should initialize agency" do
        expect(assigns(:agency).class).to eq agency_class
      end

      it "should have #{profile_type} as profile type on form" do
        expect(assigns(:agency).profile_type).to eq (params[:profile_type] || profile_type)
      end
    end

    describe "GET new", dbclean: :after_each do

      shared_examples_for "initialize profile for new" do |profile_type|

        before do
          user = self.send("#{profile_type}_user")
          sign_in user if user
          get :new, profile_type: profile_type
        end

        it "should render new template" do
          expect(response).to render_template("new")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      it_behaves_like "initialize profile for new", "benefit_sponsor"
      it_behaves_like "initialize profile for new", "broker_agency"
      # it_behaves_like "initialize profile for new", "issuer"
      # it_behaves_like "initialize profile for new", "general_agency"
      # it_behaves_like "initialize profile for new", "contact_center"
      # it_behaves_like "initialize profile for new", "fedhb"

      it_behaves_like "initialize registration form", :new, {profile_type: "benefit_sponsor"}, "benefit_sponsor"
      it_behaves_like "initialize registration form", :new, {profile_type: "broker_agency"}, "broker_agency"
      # it_behaves_like "initialize profile for new", :new, { profile_type: "issuer" }
      # it_behaves_like "initialize profile for new", :new, { profile_type: "general_agency" }
      # it_behaves_like "initialize profile for new", :new, { profile_type:  "contact_center" }
      # it_behaves_like "initialize profile for new", :new, { profile_type: "fedhb" }

      describe "for new on broker_agency_portal", dbclean: :after_each do
        context "for new on broker_agency_portal click without user" do

          before :each do
            get :new, profile_type: "broker_agency", portal: true
          end

          it "should redirect to sign_up page if current user doesn't exist" do
            expect(response.location.include?("users/sign_in")).to eq true
          end

          it "should set the value of portal on form instance to true" do
            expect(assigns(:agency).portal).to eq true
          end
        end

        context "for new on broker_agency_portal click without user" do
          let(:broker_person) { FactoryGirl.create(:person, :with_broker_role) }
          let(:broker_user) { FactoryGirl.create(:user, person: broker_person) }
          let(:broker_agency_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
          let(:broker_agency_id) { broker_agency_organization.broker_agency_profile.id }

          before :each do
            broker_person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            sign_in broker_user
            get :new, profile_type: "broker_agency", portal: true
          end

          it "should redirect to show page if current user exists and passes the pundit" do
            expect(response).to redirect_to(profiles_broker_agencies_broker_agency_profile_path(:id => broker_agency_id))
          end

          it "should set the value of portal on form instance to true" do
            expect(assigns(:agency).portal).to eq true
          end
        end
      end
    end

    describe "POST create", dbclean: :after_each do

      context "creating profile" do

        let(:benefit_sponsor_params) {
          {
            :profile_type => "benefit_sponsor",
            :staff_roles_attributes => staff_roles_attributes,
            :organization => benefit_sponsor_organization
          }
        }

        let(:broker_agency_params) {
          {
            :profile_type => "broker_agency",
            :staff_roles_attributes => staff_roles_attributes,
            :organization => broker_organization
          }
        }

        shared_examples_for "store profile for create" do |profile_type|

          before :each do
            site.benefit_markets.first.save!
            user = self.send("#{profile_type}_user")
            sign_in user if user
            post :create, :agency => self.send("#{profile_type}_params")
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should redirect to home page of benefit_sponsor" do
            expect(response.location.include?("tab=home")).to eq true if profile_type == "benefit_sponsor"
          end

          it "should redirect to new for broker agency" do
            expect(response.location.include?("new?profile_type=broker_agency")).to eq true if profile_type == "broker_agency"
          end
        end

        it_behaves_like "store profile for create", "benefit_sponsor"
        it_behaves_like "store profile for create", "broker_agency"
        # it_behaves_like "store profile for create", "issuer"
        # it_behaves_like "store profile for create", "general_agency"
        # it_behaves_like "store profile for create", "contact_center"
        # it_behaves_like "store profile for create", "fedhb"

        it_behaves_like "initialize registration form", :create, {}, "benefit_sponsor"
        it_behaves_like "initialize registration form", :create, {}, "broker_agency"
        # it_behaves_like "initialize profile for new", :create, { profile_type: "issuer" }
        # it_behaves_like "initialize profile for new", :create, { profile_type: "general_agency" }
        # it_behaves_like "initialize profile for new", :create, { profile_type: "contact_center" }
        # it_behaves_like "initialize profile for new", :create, { profile_type: "fedhb" }

        shared_examples_for "fail store profile for create if params invalid" do |profile_type|

          before do
            sign_in user
            address_attributes.merge!({
              kind: nil
            })
            post :create, :agency => self.send("#{profile_type}_params")
          end

          it "should success" do
            expect(response).to have_http_status(:success)
          end

          it "should render new" do
            expect(response).to render_template :new
          end

          it "should have profile_type in params" do
            expect(controller.params[:agency][:profile_type] == "benefit_sponsor").to eq true if profile_type == "benefit_sponsor"
            expect(controller.params[:agency][:profile_type] == "broker_agency").to eq true if profile_type == "broker_agency"
          end
        end

        it_behaves_like "fail store profile for create if params invalid", "benefit_sponsor"
        it_behaves_like "fail store profile for create if params invalid", "broker_agency"
        # it_behaves_like "fail store profile for create if params invalid", "issuer"
        # it_behaves_like "fail store profile for create if params invalid", "general_agency"
        # it_behaves_like "fail store profile for create if params invalid", "contact_center"
        # it_behaves_like "fail store profile for create if params invalid", "fedhb"

      end
    end

    describe "GET edit", dbclean: :after_each do
      let!(:benefit_sponsor) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:benefit_sponsorship) {
        benefit_sponsorship = benefit_sponsor.profiles.first.add_benefit_sponsorship
        benefit_sponsorship.save }
      let(:broker_agency)   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
      let!(:staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: benefit_sponsor.profiles.first.id)}
      let!(:employer_staff_roles) { person.employer_staff_roles << staff_role }
      let!(:broker_role) {FactoryGirl.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency.profiles.first.id,person:person)}
      let!(:update_profile) { broker_agency.profiles.first.update_attributes(primary_broker_role_id: broker_role.id)}

      shared_examples_for "initialize profile for edit" do |profile_type|

        before do
          sign_in edit_user
          @id = self.send(profile_type).profiles.first.id.to_s
          get :edit, id: @id
        end

        it "should render edit template" do
          expect(response).to render_template("edit")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end

        it "should initialize agency" do
          expect(assigns(:agency).class).to eq agency_class
        end

        it "should have #{profile_type} as profile type on form" do
          expect(assigns(:agency).profile_type).to eq profile_type
        end

        it "should have #{nil} as profile id on form" do
          expect(assigns(:agency).profile_id).to eq @id
        end
      end

      it_behaves_like "initialize profile for edit", "benefit_sponsor"
      it_behaves_like "initialize profile for edit", "broker_agency"
      # it_behaves_like "initialize profile for new", "issuer"
      # it_behaves_like "initialize profile for new", "general_agency"
      # it_behaves_like "initialize profile for new", "contact_center"
      # it_behaves_like "initialize profile for new", "fedhb"

      it_behaves_like "initialize registration form", :edit, { id: "id"}, "benefit_sponsor"
      it_behaves_like "initialize registration form", :edit, { id: "id" }, "broker_agency"
      # it_behaves_like "initialize profile for new", :edit, { profile_type: "issuer" }
      # it_behaves_like "initialize profile for new", :edit, { profile_type: "general_agency" }
      # it_behaves_like "initialize profile for new", :edit, { profile_type: "contact_center" }
      # it_behaves_like "initialize profile for new", :edit, { profile_type: "fedhb" }
    end

    describe "PUT update", dbclean: :after_each do

      context "updating profile" do

        let(:person) { FactoryGirl.create :person}

        let(:benefit_sponsor) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:broker_agency)   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

        let(:benefit_sponsor_params) {
          {
            :id => benefit_sponsor.profiles.first.id,
            :staff_roles_attributes => staff_roles_attributes,
            :organization => benefit_sponsor_organization
          }
        }

        let(:broker_agency_params) {
          {
            :id => broker_agency.profiles.first.id,
            :staff_roles_attributes => staff_roles_attributes,
            :organization => broker_organization
          }
        }

        def sanitize_attributes(profile_type)
          employer_profile_attributes.merge!({
            id: self.send(profile_type).profiles.first.id.to_s
          })

          broker_profile_attributes.merge!({
            id: self.send(profile_type).profiles.first.id.to_s
          })

          staff_roles_attributes[0].merge!({
            person_id: person.id
          })
        end

        shared_examples_for "store profile for update" do |profile_type|

          before :each do
            sanitize_attributes(profile_type)
            sign_in update_user
            put :update, :agency => self.send("#{profile_type}_params"), :id => self.send("#{profile_type}_params")[:id]
          end

          it "should initialize agency" do
            expect(assigns(:agency).class).to eq agency_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should redirect to edit for benefit_sponsor" do
            expect(response.location.include?("/edit")).to eq true if profile_type == "benefit_sponsor"
          end

          it "should redirect to show for broker_agency" do
            expect(response.location.include?("/broker_agency_profiles/")).to eq true if profile_type == "broker_agency"
          end
        end

        it_behaves_like "store profile for update", "benefit_sponsor"
        it_behaves_like "store profile for update", "broker_agency"
        # it_behaves_like "store profile for update", "issuer"
        # it_behaves_like "store profile for update", "general_agency"
        # it_behaves_like "store profile for update", "contact_center"
        # it_behaves_like "store profile for update", "fedhb"

        shared_examples_for "fail store profile for update if params invalid" do |profile_type|

          before do
            sign_in update_user
            sanitize_attributes(profile_type)
            address_attributes.merge!({
              kind: nil
            })
            put :update, :agency => self.send("#{profile_type}_params"), :id => self.send("#{profile_type}_params")[:id]
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should redirect to new" do
            expect(response.location.include?("/edit")).to eq true
          end
        end

        it_behaves_like "fail store profile for update if params invalid", "benefit_sponsor"
        it_behaves_like "fail store profile for update if params invalid", "broker_agency"
        # it_behaves_like "fail store profile for update if params invalid", "issuer"
        # it_behaves_like "fail store profile for update if params invalid", "general_agency"
        # it_behaves_like "fail store profile for update if params invalid", "contact_center"
        # it_behaves_like "fail store profile for update if params invalid", "fedhb"
      end
    end
  end
end
