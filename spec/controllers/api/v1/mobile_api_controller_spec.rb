require 'rails_helper'
require 'support/brady_bunch'

RSpec.describe Api::V1::MobileApiController, dbclean: :after_each do

  describe "get employers_list" do
    let!(:broker_role) { FactoryGirl.create(:broker_role) }
    let(:person) { double("person", broker_role: broker_role, first_name: "Brunhilde") }
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :person => person) }
    let(:organization) {
      o = FactoryGirl.create(:employer)
      a = o.primary_office_location.address
      a.address_1 = '500 Employers-Api Avenue'
      a.address_2 = '#555'
      a.city = 'Washington'
      a.state = 'DC'
      a.zip = '20001'
      o.primary_office_location.phone = Phone.new(:kind => 'main', :area_code => '202', :number => '555-9999')
      o.save
      o
    }
    let(:broker_agency_profile) {
      profile = FactoryGirl.create(:broker_agency_profile, organization: organization)
      broker_role.broker_agency_profile_id = profile.id
      profile
    }

    let(:staff_user) { FactoryGirl.create(:user) }
    let(:staff) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user
      s.first_name = "Seymour"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'seymour@example.com')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0000')
      s.save
      s
    end

    let(:staff_user2) { FactoryGirl.create(:user) }
    let(:staff2) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user2
      s.first_name = "Beatrice"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'beatrice@example.com')
      s.phones << ::Phone.new(:kind => 'work', :area_code => '202', :number => '555-0001')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0002')
      s.save
      s
    end

    let (:broker_agency_account) {
      FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile)
    }
    let (:employer_profile) do
      e = FactoryGirl.create(:employer_profile, organization: organization)
      e.broker_agency_accounts << broker_agency_account
      e.save
      e
    end

    before(:each) do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      sign_in(user)
    end

    it "should get summaries for employers where broker_agency_account is active" do

      #TODO tests for open_enrollment_start_on, open_enrollment_end_on, start_on, is_renewing?, etc

      staff.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
      staff2.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
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
      # TODO check additional fields? they are checked at the lower level...
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

  # **********************************////////////************************************
  context "\nVarious scenarios for testing functionality and security of Mobile api controller actions:\n" do
    include_context "BradyWorkAfterAll"

    before :each do
      create_brady_census_families
      carols_plan_year.update_attributes(aasm_state: "published") if carols_plan_year.aasm_state != "published"
    end

    context " (for this we are using BradyBunch and BradyWorkAfterAll support files)\n " do
      include_context "BradyBunch"
      attr_reader :mikes_organization, :mikes_employer, :mikes_family, :carols_organization, :carols_employer, :carols_family, :mikes_plan_year, :carols_plan_year, :carols_benefit_group

      # Mikes Factory records
      let!(:mikes_broker_org) { FactoryGirl.create(:organization) }
      let!(:mikes_broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: mikes_broker_org) }
      let!(:mikes_broker_role) { FactoryGirl.create(:broker_role, broker_agency_profile_id: mikes_broker_agency_profile.id) }
      let!(:mikes_broker_agency_account) { FactoryGirl.create(:broker_agency_account, broker_agency_profile: mikes_broker_agency_profile, writing_agent: mikes_broker_role, family: mikes_family) }
      let(:mikes_employer_profile) { mikes_employer.tap do |employer|
        employer.organization = mikes_organization
        employer.broker_agency_profile = mikes_broker_agency_profile
        employer.broker_role_id = mikes_broker_role._id
        employer.broker_agency_accounts = [mikes_broker_agency_account]
        employer.plan_years = [mikes_plan_year]
      end
      mikes_employer.save
      mikes_employer
      }


      let!(:mikes_broker) { FactoryGirl.create(:user, person: mikes_broker_role.person, roles: [:broker]) }
      let!(:mikes_employer_profile_person) { FactoryGirl.create(:person, first_name: "Fring") }
      let!(:mikes_employer_profile_staff_role) { FactoryGirl.create(:employer_staff_role, person: mikes_employer_profile_person, employer_profile_id: mikes_employer_profile.id) }
      let!(:mikes_employer_profile_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => false, :has_employer_staff_role? => true, :has_broker_role? => false, :person => mikes_employer_profile_staff_role.person) }


      #Carols Factory records
      let!(:carols_broker_org) { FactoryGirl.create(:organization, legal_name: "Alphabet Agency", dba: "ABCD etc") }
      let!(:carols_broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: carols_broker_org) }
      let!(:carols_broker_role) { FactoryGirl.create(:broker_role, broker_agency_profile_id: carols_broker_agency_profile.id) }
      let!(:carols_broker_agency_account) { FactoryGirl.create(:broker_agency_account, broker_agency_profile: carols_broker_agency_profile, writing_agent: carols_broker_role, family: carols_family) }
      let!(:person) { carols_broker_role.person.tap do |person|
        person.first_name = "Walter"
        person.last_name = "White"
      end
      carols_broker_role.person.save
      carols_broker_role.person
      }

      let!(:carols_broker) { FactoryGirl.create(:user, person: carols_broker_role.person, roles: [:broker]) }
      let!(:carols_employer_profile) { carols_employer.tap do |carol|
        carol.organization = carols_organization
        carol.broker_agency_profile = carols_broker_agency_profile
        carol.broker_role_id = carols_broker_role._id
        carol.broker_agency_accounts = [carols_broker_agency_account]
      end
      carols_employer.save
      carols_employer
      }
      let!(:carols_employer_profile_person) { FactoryGirl.create(:person, first_name: "Pinkman") }
      let!(:carols_employer_profile_staff_role) { FactoryGirl.create(:employer_staff_role, person: carols_employer_profile_person, employer_profile_id: carols_employer_profile.id) }
      let!(:carols_employer_profile_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => false, :has_employer_staff_role? => true, :has_broker_role? => false, :person => carols_employer_profile_staff_role.person) }
      let!(:carols_renewing_plan_year) { FactoryGirl.create(:renewing_plan_year, aasm_state: "renewing_draft", employer_profile: carols_employer, benefit_groups: [carols_benefit_group]) }

      #HBX Admin Factories
      let(:hbx_person) { FactoryGirl.create(:person, first_name: "Jessie") }
      let!(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: hbx_person) }
      let!(:hbx_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :has_broker_role? => false, :person => hbx_staff_role.person) }

      #Mikes specs begin
      context "Mike's broker" do

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

          #expect(mikes_employer_profile.active_plan_year).to_not be nil
          #print "\n>>>> py: #{mikes_employer_profile.active_plan_year.inspect}\n"

          get :employer_details, {employer_profile_id: mikes_employer_profile.id.to_s}, format: :json
          @output = JSON.parse(response.body)

          expect(response).to have_http_status(:success)
          expect(@output["employer_name"]).to eq "Mike's Architects Limited"
          expect(@output["employees_total"]).to eq 1
          expect(@output["binder_payment_due"]).to eq ""
          expect(@output["active_general_agency"]).to be(nil)
          plan_year = @output["plan_years"].first
          expect(plan_year["open_enrollment_begins"]).to eq mikes_employer_profile.active_plan_year.open_enrollment_start_on.strftime("%Y-%m-%d")
          expect(plan_year["open_enrollment_ends"]).to eq mikes_employer_profile.active_plan_year.open_enrollment_end_on.strftime("%Y-%m-%d")
          expect(plan_year["plan_year_begins"]).to eq mikes_employer_profile.active_plan_year.start_on.strftime("%Y-%m-%d")
          expect(plan_year["renewal_in_progress"]).to be_falsey
          expect(plan_year["renewal_application_available"]).to eq "2016-08-01"
          expect(plan_year["renewal_application_due"]).to eq mikes_plan_year.due_date_for_publish.strftime("%Y-%m-%d")
          expect(plan_year["minimum_participation_required"]).to eq 1

          #TODO Venu & Pavan: can we get some real plan offerings here?
          #it would be cool if Mike had just active but Carol had active and renewal, for instance
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
          pending("add default id for employer account")
          get :employee_roster, format: :json
          @output = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(response.content_type).to eq "application/json"
          expect(@output["employer_name"]).to eq(carols_employer_profile.legal_name)
          expect(@output["roster"].blank?).to be_falsey
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
end

