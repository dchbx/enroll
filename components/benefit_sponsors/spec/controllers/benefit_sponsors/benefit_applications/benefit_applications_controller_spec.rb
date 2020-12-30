require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_product_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller, dbclean: :after_each do
   # include_context "setup benefit market with market catalogs and product packages"

    routes { BenefitSponsors::Engine.routes }
    let(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
    let(:benefit_market) { site.benefit_markets.first }
    let(:effective_period) { (effective_period_start_on..effective_period_end_on) }
    # let(:premium_tabels) { FactoryBot.create(:benefit_markets_products_premium_table, rating_area: ben_app1.recorded_rating_area_id)}
    let!(:current_benefit_market_catalog) do
      BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
      benefit_market.benefit_market_catalogs.where(
        "application_period.min" => effective_period_start_on
      ).first
    end

    let(:service_areas) do
      ::BenefitMarkets::Locations::ServiceArea.where(
        :active_year => current_benefit_market_catalog.application_period.min.year
      ).all.to_a
    end

    let(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.where(
        :active_year => current_benefit_market_catalog.application_period.min.year
      ).first
    end

    let(:current_effective_date)  { effective_period_start_on }
    let(:product_package) { current_benefit_market_catalog.product_packages.first }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let(:form_class)  { BenefitSponsors::Forms::BenefitApplicationForm }

    let!(:permission)               { FactoryBot.create(:permission, :hbx_staff) }
    let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:hbx_person)               { FactoryBot.create(:person, user: user_with_hbx_staff_role )}
    let(:organization_with_hbx_profile)  { site.owner_organization }

    let!(:person1) { FactoryBot.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person1 ) }
    let!(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let!(:employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: benefit_sponsorship.profile.id)}
    let!(:person) { FactoryBot.create(:person, employer_staff_roles:[employer_staff_role]) }
    let!(:user) { FactoryBot.create_default :user, person: person}

    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryBot.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: service_areas,
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0],
        employer_attestation: employer_attestation) 
    end

    let(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }

    let(:benefit_application_params) {

      {
        :start_on => effective_period_start_on,
        :end_on => effective_period_end_on,
        :fte_count => "5",
        :pte_count => "5",
        :msp_count => "5",
        :open_enrollment_start_on => open_enrollment_period_start_on,
        :open_enrollment_end_on => open_enrollment_period_end_on,
        :benefit_sponsorship_id => benefit_sponsorship_id
      }
    }

    shared_context "shared_stuff", :shared_context => :metadata do
      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) {
        {
          recorded_rating_area: rating_area,
          recorded_service_areas: service_areas,
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          fte_count: "5",
          pte_count: "5",
          msp_count: "5",
          benefit_sponsor_catalog_id: BSON::ObjectId.new

        }
      }

      let(:ben_app)       { benefit_sponsorship.benefit_applications.build(params) }
    end

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
      benefit_sponsorship.benefit_market.site_urn = site.site_key
      benefit_sponsorship.save
      user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id, permission_id: permission.id)
      user_with_hbx_staff_role.person.hbx_staff_role.save!
      user_with_broker_role.person.broker_role.update_attributes!(aasm_state: 'active')
    end

    describe "GET new", :dbclean => :around_each do
      include_context 'shared_stuff'

      it "should initialize the form" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      it "should be a success" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(response).to have_http_status(:success)
        end
      end

      it "should render new template" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(response).to render_template("new")
        end
      end

      def sign_in_and_do_new(user)
        sign_in user
        get :new, params: { benefit_sponsorship_id: benefit_sponsorship_id }
      end
    end

    describe "POST create", :dbclean => :around_each do
      include_context 'shared_stuff'

      it "should redirect" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
            expect(response).to have_http_status(:redirect)
        end
      end

      it "should redirect to benefit packages new" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
          expect(response.location.include?("benefit_packages/new")).to be_truthy
        end
      end

      it "should initialize form" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      context "when create fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to new" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_do_create(login_user)
            expect(response).to have_http_status(:redirect)
          end
        end

        it "should return error messages" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_do_create(login_user)
            expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
          end
        end
      end

      def sign_in_and_do_create(user)
        sign_in user
        post :create, params: {benefit_sponsorship_id: benefit_sponsorship_id, :benefit_application => benefit_application_params}
      end
    end

    describe "GET late_rates_check", :dbclean => :around_each do

      before { sign_in user }

      it "should return false when it is not in late rate scenario" do
        get :late_rates_check, xhr: true, params: { :start_on_date => effective_period_start_on.strftime('%m/%d/%Y'), benefit_sponsorship_id: "123" }
        expect(response.body).to eq "false"
      end

      it "should return true during late rates scenario" do
        get :late_rates_check, xhr: true, params: { :start_on_date => effective_period_start_on.prev_year.strftime('%m/%d/%Y'), benefit_sponsorship_id: "123" }
        expect(response.body).to eq "true"
      end
    end

    describe "GET edit", :dbclean => :around_each do
      include_context 'shared_stuff'

      before do
        ben_app.save
      end

      it "should be a success" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in login_user
          get :edit, xhr: true, params: {benefit_sponsorship_id: benefit_sponsorship_id, id: ben_app.id.to_s, benefit_application: benefit_application_params}
          expect(response).to have_http_status(:success)
        end
      end

      it "should render edit template" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in login_user
          get :edit, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id, id: ben_app.id.to_s, benefit_application: benefit_application_params }
          expect(response).to render_template("edit")
        end
      end

      it "should initialize form" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in login_user
          get :edit, xhr: true, params: {benefit_sponsorship_id: benefit_sponsorship_id, id: ben_app.id.to_s, benefit_application: benefit_application_params}
          expect(form_class).to respond_to(:for_edit)
        end
      end
    end

    describe "POST update", :dbclean => :around_each do
      include_context 'shared_stuff'

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
      end

      it "should be a success" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          # expect(response).to have_http_status(:success)
        end
      end

      it "should initialize form" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      it "should redirect to benefit packages index" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          expect(response.location.include?("benefit_packages")).to be_truthy
        end
      end

      context "when update fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to edit" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_do_update(login_user)
            expect(response).to render_template("edit")
          end
        end

        it "should return error messages" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_do_update(login_user)
            expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
          end
        end
      end

      def sign_in_and_do_update(user)
        sign_in user
        put :update, xhr: true, params: {:id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params}
      end
    end

    describe "POST publish", :dbclean => :around_each do

      include_context 'shared_stuff'
      include_context "setup initial benefit application"

      let(:aasm_state) { :draft }
      let(:benefit_application_id) { initial_application.id.to_s }

      def sign_in_and_submit_application(user)
        sign_in user
        post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }
      end

      context "benefit application published sucessfully" do
        it "should redirect with success message for broker" do
          [user_with_broker_role].each do |login_user|
            sign_in_and_submit_application(login_user)
            expect(flash[:notice]).to eq "Plan Year successfully published."
          end
        end
        it "should redirect with success message for amdin" do
          [user_with_hbx_staff_role].each do |login_user|
            sign_in_and_submit_application(login_user)
            expect(flash[:notice]).to eq "Plan Year successfully published."
          end
        end
        it "should redirect with success message for employer" do
          [user].each do |login_user|
            sign_in_and_submit_application(login_user)
            expect(flash[:notice]).to eq "Plan Year successfully published."
          end
        end
      end

      context "benefit application published sucessfully but with warning" do

        before do
          allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive_message_chain('non_owner_employee_present?').and_return(false)
        end

        it "should redirect with success message for employer" do
          [user].each do |login_user|
            sign_in login_user
            post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }
            expect(flash[:notice]).to eq "Plan Year successfully published."
            expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
          end
        end

        it "should redirect with success message for admin" do
          [user_with_hbx_staff_role].each do |login_user|
            sign_in login_user
            post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }
            expect(flash[:notice]).to eq "Plan Year successfully published."
            expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
          end
        end

        it "should redirect with success message for broker" do
          [user_with_broker_role].each do |login_user|
            sign_in login_user
            post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }
            expect(flash[:notice]).to eq "Plan Year successfully published."
            expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
          end
        end
      end

      context "benefit application is not submitted due to warnings" do

        before :each do
          allow_any_instance_of(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile).to receive(:is_primary_office_local?).and_return(false)
        end

        it "should display warnings" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in login_user
            post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }#, :benefit_sponsorship_id => benefit_sponsorship_id
            have_http_status(:success)
          end
        end
      end

      context "benefit application is not submitted" do
        let(:aasm_state) { :denied }

        it "should redirect with errors" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in login_user
            post :submit_application, xhr: true, params: { benefit_sponsorship_id: benefit_sponsorship_id.to_s, benefit_application_id: benefit_application_id }#, :benefit_sponsorship_id => benefit_sponsorship_id
            expect(flash[:error]).to match(/Plan Year failed to publish/)
          end
        end
      end
    end

    describe "POST force publish", :dbclean => :around_each do
      include_context 'shared_stuff'
      include_context "setup initial benefit application"

      let(:aasm_state) { :draft }
      let(:ben_app) { initial_application }

      def sign_in_and_force_submit_application(user)
        sign_in user
        post :force_submit_application, params: { :benefit_application_id => ben_app.id.to_s, benefit_sponsorship_id: benefit_sponsorship_id.to_s }
      end

      it "should redirect" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          expect(response).to have_http_status(:redirect)
        end
      end

      # TODO: FIX ME - Add below test after adding business rules engine
      it "should expect benefit application state to be pending" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          ben_app.reload
          # expect(ben_app.aasm_state).to eq :pending
        end
      end

      it "should display errors" do
        [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          expect(flash[:error]).to match(/this application is ineligible for coverage/)
        end
      end
    end

    describe "POST revert", :dbclean => :around_each do
      include_context 'shared_stuff'
      include_context "setup initial benefit application"

      let(:benefit_application) { initial_application }

      def sign_in_and_revert(user)
        sign_in user
        post :revert, params: { :benefit_application_id => benefit_application.id.to_s, benefit_sponsorship_id: benefit_sponsorship_id }
      end

      context "when there is no eligible application to revert" do
        let(:aasm_state) { :draft }

        it "should redirect" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(response).to have_http_status(:success)
          end
        end

        it "should display error message" do
          [user_with_hbx_staff_role, user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:error]).to match(/Plan Year could not be reverted to draft state/)
          end
        end
      end

      context "when there is an eligible application to revert" do
        let(:aasm_state) { :approved }

        it "employer should revert benefit application" do
          [user].each do |login_user|
            sign_in_and_revert(login_user)
            expect(ben_app.aasm_state).to eq :draft
          end
        end
        it "broker should revert benefit application" do
          [user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(ben_app.aasm_state).to eq :draft
          end
        end
        it "admin should revert benefit application" do
          [user_with_hbx_staff_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(ben_app.aasm_state).to eq :draft
          end
        end

        it "should display flash messages for employer" do
          [user].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:notice]).to match(/Plan Year successfully reverted to draft state./)
          end

        end
        it "should display flash messages for broker" do
          [user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:notice]).to match(/Plan Year successfully reverted to draft state./)
          end
        end
        it "should display flash messages for admin" do
          [user_with_hbx_staff_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:notice]).to match(/Plan Year successfully reverted to draft state./)
          end
        end

      end
    end
  end
end
