require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:form_class)  { BenefitSponsors::Forms::BenefitApplicationForm }
    let(:person) { FactoryGirl.create(:person) }
    let!(:user) { FactoryGirl.create_default :user, person: person}
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: [service_area],
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
          recorded_service_areas: [service_area],
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          fte_count: "5",
          pte_count: "5",
          msp_count: "5",
        }
      }

      let(:ben_app)       { benefit_sponsorship.benefit_applications.build(params) }
    end

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
      benefit_sponsorship.benefit_market.site_urn = site.site_key
      benefit_sponsorship.save
    end

    describe "GET new", dbclean: :after_each do
      include_context 'shared_stuff'

      it "should initialize the form" do
        sign_in_and_do_new
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should be a success" do
        sign_in_and_do_new
        expect(response).to have_http_status(:success)
      end

      it "should render new template" do
        sign_in_and_do_new
        expect(response).to render_template("new")
      end

      def sign_in_and_do_new
        sign_in user
        get :new, :benefit_sponsorship_id => benefit_sponsorship_id
      end
    end

    describe "POST create", dbclean: :after_each do
      include_context 'shared_stuff'

      it "should redirect" do
        sign_in_and_do_create
        expect(response).to have_http_status(:redirect)
      end

      it "should redirect to benefit packages new" do
        sign_in_and_do_create
        expect(response.location.include?("benefit_packages/new")).to be_truthy
      end

      it "should initialize form" do
        sign_in_and_do_create
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      context "when create fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to new" do
          sign_in_and_do_create
          expect(response).to render_template("new")
        end

        it "should return error messages" do
          sign_in_and_do_create
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_create
        sign_in user
        post :create, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "GET edit", dbclean: :after_each do
      include_context 'shared_stuff'

      before do
        ben_app.save
      end

      it "should be a success" do
        sign_in user
        xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to have_http_status(:success)
      end

      it "should render edit template" do
        sign_in user
        xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to render_template("edit")
      end

      it "should initialize form" do
        sign_in user
        xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(form_class).to respond_to(:for_edit)
      end
    end

    describe "POST update" do
      include_context 'shared_stuff'

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
      end

      it "should be a success" do
        sign_in_and_do_update
        # expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        sign_in_and_do_update
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should redirect to benefit packages index" do
        sign_in_and_do_update
        expect(response.location.include?("benefit_packages")).to be_truthy
      end

      context "when update fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to edit" do
          sign_in_and_do_update
          expect(response).to render_template("edit")
        end

        it "should return error messages" do
          sign_in_and_do_update
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_update
        sign_in user
        xhr :put, :update, :id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "POST publish" do

      include_context 'shared_stuff'

      let!(:benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship)
        application.benefit_sponsor_catalog.save!
        application
      }
      let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }

      before do
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_submit_application
        sign_in user
        post :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "benefit application published sucessfully" do
        it "should redirect with success message" do
          sign_in_and_submit_application
          expect(flash[:notice]).to eq "Benefit Application successfully published."
        end
      end

      context "benefit application published sucessfully but with warning" do

        before do
          allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive_message_chain('non_owner_employee_present?').and_return(false)
        end

        it "should redirect with success message" do
          sign_in user
          xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
          expect(flash[:notice]).to eq "Benefit Application successfully published."
          expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
        end
      end

      context "benefit application is not submitted due to warnings" do

        before :each do
          allow_any_instance_of(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile).to receive(:is_primary_office_local?).and_return(false)
        end

        it "should display warnings" do
          sign_in user
          xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
          have_http_status(:success)
        end
      end

      context "benefit application is not submitted" do
        let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :denied) }

        it "should redirect with errors" do
          sign_in user
          xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
          expect(flash[:error]).to match(/Benefit Application failed to submit/)
        end
      end
    end

    describe "POST force publish", dbclean: :after_each do
      include_context 'shared_stuff'

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_force_submit_application
        sign_in user
        post :force_submit_application, :benefit_application_id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      it "should redirect" do
        sign_in_and_force_submit_application
        expect(response).to have_http_status(:redirect)
      end

      # TODO: FIX ME - Add below test after adding business rules engine
      it "should expect benefit application state to be pending" do
        sign_in_and_force_submit_application
        ben_app.reload
        # expect(ben_app.aasm_state).to eq :pending
      end

      it "should display errors" do
        sign_in_and_force_submit_application
        expect(flash[:error]).to match(/this application is ineligible for coverage/)
      end
    end

    describe "POST revert", dbclean: :after_each do
      include_context 'shared_stuff'
      let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :draft) }

      before do
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_revert
        sign_in user
        post :revert, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "when there is no eligible application to revert" do
        it "should redirect" do
          sign_in_and_revert
          expect(response).to have_http_status(:success)
        end

        it "should display error message" do
          sign_in_and_revert
          expect(flash[:error]).to match(/Plan Year could not be reverted to draft state/)
        end
      end

      context "when there is an eligible application to revert" do
        let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :approved) }

        it "should revert benefit application" do
          sign_in_and_revert
          expect(ben_app.aasm_state).to eq :draft
        end

        it "should display flash messages" do
          sign_in_and_revert
          expect(flash[:notice]).to match(/Plan Year successfully reverted to draft state./)
        end
      end
    end
  end
end
