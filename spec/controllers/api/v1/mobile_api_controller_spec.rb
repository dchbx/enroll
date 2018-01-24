require 'rails_helper'
require 'support/brady_bunch'
require 'lib/api/v1/support/mobile_broker_data'
require 'lib/api/v1/support/mobile_broker_agency_data'

RSpec.describe Api::V1::MobileApiController, dbclean: :after_each do
  include_context 'broker_agency_data'

  describe "GET employers_list" do

    it "should get summaries for employers where broker_agency_account is active" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      xhr :get, :employers_list, id: broker_agency_profile.id, format: :json
      expect(response).to have_http_status(:success), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
      details = JSON.parse(response.body)['broker_clients']
      detail = JSON.generate(details[0])
      detail = JSON.parse(detail, :symbolize_names => true)
      expect(details.count).to eq 1
      expect(detail[:employer_name]).to eq employer_profile.legal_name
      contacts = detail[:contact_info]

      seymour = contacts.detect { |c| c[:first] == 'Seymour' }
      beatrice = contacts.detect { |c| c[:first] == 'Beatrice' }
      office = contacts.detect { |c| c[:first] == 'Primary' }
      expect(seymour[:mobile]).to eq '(202) 555-0000'
      expect(seymour[:phone]).to eq ''
      expect(beatrice[:phone]).to eq '(202) 555-0001'
      expect(beatrice[:mobile]).to eq '(202) 555-0002'
      expect(seymour[:emails]).to include('seymour@example.com')
      expect(beatrice[:emails]).to include('beatrice@example.com')
      expect(office[:phone]).to eq '(202) 555-9999'
      expect(office[:address_1]).to eq '500 Employers-Api Avenue'
      expect(office[:address_2]).to eq '#555'
      expect(office[:city]).to eq 'Washington'
      expect(office[:state]).to eq 'DC'
      expect(office[:zip]).to eq '20001'

      output = JSON.parse(response.body)

      expect(output["broker_name"]).to eq("Brunhilde")
      employer = output["broker_clients"][0]
      expect(employer).not_to be(nil), "in #{output}"
      expect(employer["employer_name"]).to eq(employer_profile.legal_name)
      expect(employer["employees_total"]).to eq(employer_profile.roster_size)
      expect(employer["employer_details_url"]).to end_with("mobile_api/employer_details/#{employer_profile.id}")
    end
  end

  describe "GET employer_details" do
    let(:user) { double("user", :person => person) }
    let(:person) { double("person", :employer_staff_roles => [employer_staff_role]) }
    let(:employer_staff_role) { double(:employer_profile_id => employer_profile.id) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, aasm_state: "published") }
    let!(:benefit_group) { FactoryGirl.create(:benefit_group, :with_valid_dental, plan_year: plan_year, title: "Test Benefit Group") }
    let!(:employer_profile) { plan_year.employer_profile }
    let!(:employee1) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }
    let!(:employee2) { FactoryGirl.create(:census_employee, :with_enrolled_census_employee, employer_profile_id: employer_profile.id) }

    before(:each) do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
    end

    it 'should render 200 with valid ID' do
      get :employer_details, {employer_profile_id: employer_profile.id.to_s}
      expect(response).to have_http_status(200), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
      expect(response.content_type).to eq 'application/json'
    end

    it "should render 404 with Invalid ID" do
      get :employer_details, {employer_profile_id: "Invalid Id"}
      expect(response).to have_http_status(404), "expected status 404, got #{response.status}: \n----\n#{response.body}\n\n"
    end

    it "should match with the expected result set" do
      get :employer_details, {employer_profile_id: employer_profile.id.to_s}
      output = JSON.parse(response.body)
      expect(output["employer_name"]).to eq(employer_profile.legal_name)
      expect(output["employees_total"]).to eq(employer_profile.roster_size)
      expect(output["active_general_agency"]).to eq(employer_profile.active_general_agency_legal_name)
    end
  end

  context "Test functionality and security of Mobile API controller actions" do
    include_context 'BradyWorkAfterAll'
    include_context 'BradyBunch'

    before :each do
      create_brady_census_families
      carols_plan_year.update_attributes(aasm_state: "published") if carols_plan_year.aasm_state != "published"
    end

    #Mikes specs begin
    context "Mike's broker" do
      include_context 'broker_data'

      before(:each) do
        sign_in mikes_broker
        get :employers_list, format: :json
        @output = JSON.parse(response.body)
        mikes_plan_year.update_attributes(aasm_state: "published") if mikes_plan_year.aasm_state != "published"
      end

      it "should be able to login and get success status" do
        expect(@output["broker_name"]).to eq("John")
        expect(response).to have_http_status(:success), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
      end

      it "should have 1 client in their broker's employer's list" do
        expect(@output["broker_clients"].count).to eq 1
      end

      it "should be able to see only Mikes Company in the list and it shouldn't be nil" do
        expect(@output["broker_clients"][0]).not_to be(nil), "in #{@output}"
        expect(@output["broker_clients"][0]["employer_name"]).to eq(mikes_employer_profile.legal_name)
      end

      it "should be able to access Mike's employee roster" do
        get :employee_roster, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(@output["employer_name"]).to eq(mikes_employer_profile.legal_name)
        expect(@output["roster"].blank?).to be_falsey
      end

      it "should be able to access Mike's employer details" do
        expect(mikes_employer_profile.plan_years.count).to be > 0

        get :employer_details, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(@output["employer_name"]).to eq "Mike's Architects Limited"
        expect(@output["employees_total"]).to eq 1
        expect(@output["binder_payment_due"]).to eq ""
        expect(@output["active_general_agency"]).to be(nil)
        plan_year = @output["plan_years"].detect do |py|
          py["plan_year_begins"] == mikes_employer_profile.active_plan_year.start_on.strftime("%Y-%m-%d")
        end
        expect(plan_year).to_not be nil
        expect(plan_year["open_enrollment_begins"]).to eq mikes_employer_profile.active_plan_year.open_enrollment_start_on.strftime("%Y-%m-%d")
        expect(plan_year["open_enrollment_ends"]).to eq mikes_employer_profile.active_plan_year.open_enrollment_end_on.strftime("%Y-%m-%d")
        expect(plan_year["renewal_in_progress"]).to be_falsey
        expect(Date.parse(plan_year["renewal_application_available"])).to be < mikes_employer_profile.active_plan_year.start_on
        expect(plan_year["renewal_application_due"]).to eq mikes_plan_year.due_date_for_publish.strftime("%Y-%m-%d")
        expect(plan_year["minimum_participation_required"]).to eq 1
        expect(plan_year["plan_offerings"].size).to eq 1
      end

      it "should not be able to access Carol's broker's employer list" do
        get :employers_list, {id: carols_broker_agency_profile.id}, format: :json
        expect(response).to have_http_status(404)
      end

      it "should not be able to access Carol's employee roster" do
        get :employee_roster, {employer_profile_id: carols_employer_profile.id.to_s}, format: :json
        expect(response).to have_http_status(404)
      end

      it "should not be able to access Carol's employer details" do
        get :employer_details, {employer_profile_id: carols_employer_profile.id.to_s}, format: :json
        expect(response).to have_http_status(404)
      end
    end

    context "Mikes employer specs" do
      include_context 'broker_data'

      before(:each) do
        sign_in mikes_employer_profile_user
      end

      it "Mikes employer shouldn't be able to see the employers_list and should get 404 status on request" do
        get :employers_list, id: mikes_broker_agency_profile.id, format: :json
        @output = JSON.parse(response.body)
        expect(response.status).to eq 404
      end

      it "Mikes employer should be able to see his own roster" do
        get :employee_roster, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(@output["employer_name"]).to eq(mikes_employer_profile.legal_name)
        expect(@output["roster"].blank?).to be_falsey
      end

      it "Mikes employer should render 200 with valid ID" do
        get :employer_details, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(200), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
        expect(response.content_type).to eq "application/json"
      end

      it "Mikes employer should render 404 with Invalid ID" do
        get :employer_details, {employer_profile_id: "Invalid Id"}
        expect(response).to have_http_status(404), "expected status 404, got #{response.status}: \n----\n#{response.body}\n\n"
      end

      it "Mikes employer details request should match with the expected result set" do
        get :employer_details, {employer_profile_id: mikes_employer_profile.id.to_s}
        output = JSON.parse(response.body)
        expect(output["employer_name"]).to eq(mikes_employer_profile.legal_name)
        expect(output["employees_total"]).to eq(mikes_employer_profile.roster_size)
        expect(output["active_general_agency"]).to eq(mikes_employer_profile.active_general_agency_legal_name)
      end
    end

    #Carols spec begin
    context "Carols broker specs" do
      include_context 'broker_data'

      before(:each) do
        sign_in carols_broker
        get :employers_list, format: :json
        @output = JSON.parse(response.body)
      end

      it "Carols broker should be able to login and get success status" do
        expect(@output["broker_name"]).to eq("Walter")
        expect(response).to have_http_status(:success), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
      end

      it "No of broker clients in Carols broker's employer's list should be 1" do
        expect(@output["broker_clients"].count).to eq 1
      end

      it "Carols broker should be able to see only carols Company and it shouldn't be nil" do
        expect(@output["broker_clients"][0]).not_to be(nil), "in #{@output}"
        expect(@output["broker_clients"][0]["employer_name"]).to eq(carols_employer_profile.legal_name)
      end

      it "Carols broker should be able to access Carol's employee roster" do
        get :employee_roster, {employer_profile_id: carols_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(@output["employer_name"]).to eq(carols_employer_profile.legal_name)
        expect(@output["roster"]).not_to be []
        expect(@output["roster"].count).to eq 1
      end
    end

    context "Carols employer" do
      include_context 'broker_data'

      before(:each) do
        sign_in carols_employer_profile_user
      end

      it "shouldn't be able to see the employers_list and should get 404 status on request" do
        get :employers_list, id: carols_broker_agency_profile.id, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
      end

      it "should be able to see their own roster specifying id" do
        get :employee_roster, {employer_profile_id: carols_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq "application/json"
        expect(@output["employer_name"]).to eq(carols_employer_profile.legal_name)
        expect(@output["roster"].blank?).to be_falsey
      end

      it "should be able to see their own roster by default (with no id)" do
        get :my_employee_roster, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq "application/json"
        expect(@output["employer_name"]).to eq(carols_employer_profile.legal_name)
        expect(@output["roster"].blank?).to be_falsey
        expect(@output["roster"].first).to include('first_name', 'middle_name', 'last_name', 'date_of_birth', 'ssn_masked',
                                                   'is_business_owner', 'hired_on', 'enrollments')
      end

      it "should be able to see their own employer details by default (with no id)" do
        get :my_employer_details, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq "application/json"
        expect(@output["employer_name"]).to eq(carols_employer_profile.legal_name)
        expect(@output["employees_total"]).to eq 1
        expect(@output["plan_years"].first).to include('open_enrollment_begins', 'open_enrollment_ends', 'plan_year_begins',
                                                       'renewal_in_progress', 'renewal_application_available', 'renewal_application_due',
                                                       'state', 'minimum_participation_required', 'plan_offerings')
      end

      it "should not be able to see Mike's employer's roster" do
        get :employee_roster, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
        @output = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
      end

      it "should get 404 NOT FOUND seeking an invalid employer profile ID" do
        get :employer_details, {employer_profile_id: "Invalid Id"}
        expect(response).to have_http_status(404), "expected status 404, got #{response.status}: \n----\n#{response.body}\n\n"
      end

      it "details request should match with the expected result set" do
        get :employer_details, {employer_profile_id: carols_employer_profile.id.to_s}
        output = JSON.parse(response.body)
        expect(output["employer_name"]).to eq(carols_employer_profile.legal_name)
        expect(output["employees_total"]).to eq(carols_employer_profile.roster_size)
        expect(output["active_general_agency"]).to eq(carols_employer_profile.active_general_agency_legal_name)
      end
    end

    context "HBX admin specs" do
      include_context 'broker_data'

      it "HBX Admin should be able to see Mikes details" do
        sign_in hbx_user
        get :employers_list, id: mikes_broker_agency_profile.id, format: :json
        @output = JSON.parse(response.body)
        expect(@output["broker_agency"]).to eq("Turner Agency, Inc")
        expect(@output["broker_clients"].count).to eq 1
        expect(@output["broker_clients"][0]["employer_name"]).to eq(mikes_employer_profile.legal_name)
      end

      it "HBX Admin should be able to see Carols details" do
        sign_in hbx_user
        get :employers_list, id: carols_broker_agency_profile.id, format: :json
        @output = JSON.parse(response.body)
        expect(@output["broker_agency"]).to eq("Alphabet Agency")
        expect(@output["broker_clients"].count).to eq 1
        expect(@output["broker_clients"][0]["employer_name"]).to eq(carols_employer_profile.legal_name)
      end
    end

  end
end

