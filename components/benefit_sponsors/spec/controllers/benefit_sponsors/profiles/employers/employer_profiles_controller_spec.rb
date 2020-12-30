require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::EmployerProfilesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, :person => person)}

    let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)       { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)      { benefit_sponsor.employer_profile }
    let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    before do
      controller.prepend_view_path("../../app/views")
      person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: employer_profile.id
    end

    describe "GET show_pending" do
      before do
        sign_in user
        get :show_pending
      end

      it "should render show template" do
        assert_template "show_pending"
      end

      it "should return http success" do
        assert_response :success
      end
    end

    describe "GET show" do
      let!(:employees) {
        FactoryBot.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship)
      }
      context 'employee tab' do
        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          get :show, params: {id: benefit_sponsor.profiles.first.id.to_s, tab: 'employees'}
          allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
        end

        it "should render show template" do
          expect(response).to render_template("show")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'accounts tab' do
        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          get :show, params: {id: benefit_sponsor.profiles.first.id.to_s, tab: 'accounts'}
          allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
        end

        it "should render show template" do
          expect(response).to render_template("show")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end
    end

    describe "bulk employee upload" do
      context 'when a correct format is uploaded' do
        let(:file) do
          test_file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "test_data", "census_employee_import", "DCHL Employee Census.xlsx"))
          test_file.content_type = 'application/xlsx'
          test_file
        end

        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          post :bulk_employee_upload, :params => {:employer_profile_id => benefit_sponsor.profiles.first.id, :file => file}
        end

        it 'should upload successfully' do
          expect(response).to redirect_to(profiles_employers_employer_profile_path(benefit_sponsor.profiles.first, tab: 'employees'))
        end

        it 'should render flash message successfully' do
          expect(flash[:notice]).to eq("2 records uploaded from CSV")
        end
      end

      context 'when a wrong format is uploaded' do
        let(:file) { Rack::Test::UploadedFile.new(Rails.root.join("spec", "test_data", "individual_person_payloads", "individual.xml")) }

        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          post :bulk_employee_upload, :params => {:employer_profile_id => benefit_sponsor.profiles.first.id, :file => file}
        end

        it 'should throw error' do
          expect(response).to render_template("benefit_sponsors/profiles/employers/employer_profiles/_employee_csv_upload_errors", "layouts/two_column")
        end
      end
    end


    describe "GET coverage_reports" do
      let!(:employees) {
        FactoryBot.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship)
      }

      before do
        benefit_sponsorship.save!
        allow(controller).to receive(:authorize).and_return(true)
        sign_in user
        get :coverage_reports, params: { employer_profile_id: benefit_sponsor.profiles.first.id, billing_date: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime("%m/%d/%Y")}
        allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
      end

      it "should render coverage_reports template" do
        assert_template "coverage_reports"
      end

      it "should return http success" do
        assert_response :success
      end
    end

    describe "POST terminate_employee_roster_enrollments", type: :controller, dbclean: :after_each do

      let(:hbx_staff_permission) { FactoryBot.create(:permission, :hbx_staff) }
      let!(:user) { FactoryBot.create(:user) }

      context "employer with no active plan year" do
        before do
          benefit_sponsorship.save
          allow(controller).to receive(:authorize).and_return(true)
          sign_in(user)
          post :terminate_employee_roster_enrollments, params: {employer_profile_id: employer_profile.id.to_s, termination_reason: " ", termination_date: "", transmit_xml: true}, format: :js, xhr: true
        end

        it "should show an error message if no active plan year present" do
          error_message = "No Active Plan Year present, unable to terminate employee enrollments."
          expect(flash[:error]).to eq(error_message)
          redirect_path = profiles_employers_employer_profile_path(employer_profile) + "?tab=employees"
          expect(response).to redirect_to(redirect_path)
        end
      end

      context "employer with active and renewal plan year", dbclean: :after_each do
        let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area, active_year: TimeKeeper.date_of_record.prev_year.year }
        let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: TimeKeeper.date_of_record.prev_year.year }
        let(:benefit_sponsorship) do
          create(
              :benefit_sponsors_benefit_sponsorship,
              :with_organization_cca_profile,
              :with_renewal_benefit_application,
              :with_rating_area,
              :with_service_areas,
              initial_application_state: :active,
              renewal_application_state: :enrollment_open,
              default_effective_period: ((TimeKeeper.date_of_record.end_of_month + 1.day)..(TimeKeeper.date_of_record.end_of_month + 1.year)),
              site: site,
              aasm_state: :active
          )
        end

        let(:employer_profile) { benefit_sponsorship.profile }
        let(:active_benefit_package) { employer_profile.active_benefit_application.benefit_packages.first }
        let(:active_sponsored_benefit) {  employer_profile.active_benefit_application.benefit_packages.first.sponsored_benefits.first}

        let(:renewal_benefit_package) { employer_profile.renewal_benefit_application.benefit_packages.first }
        let(:renewal_sponsored_benefit) {  employer_profile.renewal_benefit_application.benefit_packages.first.sponsored_benefits.first}

        let!(:person) {FactoryBot.create(:person)}
        let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
        let!(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }
        let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

        let!(:active_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                                     household: family.latest_household,
                                                     coverage_kind: "health",
                                                     family: family,
                                                     effective_on: employer_profile.active_benefit_application.start_on,
                                                     enrollment_kind: "open_enrollment",
                                                     kind: "employer_sponsored",
                                                     aasm_state: 'coverage_selected',
                                                     benefit_sponsorship_id: benefit_sponsorship.id,
                                                     sponsored_benefit_package_id: active_benefit_package.id,
                                                     sponsored_benefit_id: active_sponsored_benefit.id,
                                                     employee_role_id: employee_role.id) }
        let!(:renewal_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                                      household: family.latest_household,
                                                      coverage_kind: "health",
                                                      family: family,
                                                      effective_on: employer_profile.renewal_benefit_application.start_on,
                                                      enrollment_kind: "open_enrollment",
                                                      kind: "employer_sponsored",
                                                      aasm_state: 'auto_renewing',
                                                      benefit_sponsorship_id: benefit_sponsorship.id,
                                                      sponsored_benefit_package_id: renewal_benefit_package.id,
                                                      employee_role_id: employee_role.id,
                                                      sponsored_benefit_id: renewal_sponsored_benefit.id) }
        before do
          census_employee.update_attributes({employee_role_id: employee_role.id})
          allow(controller).to receive(:authorize).and_return(true)
          sign_in(user)
          post :terminate_employee_roster_enrollments, params: {employer_profile_id: employer_profile.id.to_s, termination_reason: "nonpayment ", termination_date: employer_profile.active_benefit_application.end_on.strftime("%m/%d/%Y"), transmit_xml: true}, format: :js, xhr: true
        end


        it "should terminate employees enrollments for a active plan year" do
          flash_message = "Successfully terminated employee enrollments."
          expect(flash[:notice]).to eq(flash_message)
          active_enrollment.reload
          expect(active_enrollment.aasm_state).to eq('coverage_termination_pending')
          redirect_path = profiles_employers_employer_profile_path(benefit_sponsorship.profile) + "?tab=employees"
          expect(response).to redirect_to(redirect_path)
        end

        it "should cancel employees enrollments for a renewing plan year" do
          flash_message = "Successfully terminated employee enrollments."
          expect(flash[:notice]).to eq(flash_message)
          renewal_enrollment.reload
          expect(renewal_enrollment.aasm_state).to eq('coverage_canceled')
          redirect_path = profiles_employers_employer_profile_path(benefit_sponsorship.profile.id) + "?tab=employees"
          expect(response).to redirect_to(redirect_path)
        end
      end
    end
  end
end
