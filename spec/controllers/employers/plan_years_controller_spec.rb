require 'rails_helper'

RSpec.describe Employers::PlanYearsController, :dbclean => :after_each do
  let(:employer_profile_id) { EmployerProfile.new.id}
  let(:plan_year_proxy) { double(id: "id") }
  let(:employer_profile) { double(:plan_years => plan_year_proxy, find_plan_year: plan_year_proxy, id: "test") }

  let(:user) { FactoryGirl.create(:user) } 
  let(:person) { FactoryGirl.create(:person, user: user) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }

  describe "GET reference_plan_summary" do
    let(:qhp_cost_share_variance){ Products::QhpCostShareVariance.new }
    it 'should return qhp cost share variance for the plan' do
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return([qhp_cost_share_variance])
      sign_in
      xhr :get, :reference_plan_summary, coverage_kind: "health", start_on: 2016, hios_id: "48484848", employer_profile_id: "1111", format: :js
      expect(response).to have_http_status(:success)
      expect(response).to render_template("reference_plan_summary")
      expect(assigns[:visit_types].size).to eq 11
      expect(assigns[:qhps]).to be_an_instance_of(Array)
      expect(assigns[:qhps].first).to be_an_instance_of(Products::QhpCostShareVariance)
    end
  end

  describe "GET new" do

    before :each do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(Organization).to receive(:valid_carrier_names).and_return({'id' => "legal_name"})
      get :new, :employer_profile_id => employer_profile_id
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the new template" do
      expect(response).to render_template("new")
    end

    it "should generate carriers" do
      expect(assigns(:carrier_names)).to eq({'id' => "legal_name"})
      expect(assigns(:carriers_array)).to eq [['legal_name', 'id']]
    end

    it "should generate benefit_group with nil plan_option_kind" do
      benefit_group = assigns(:plan_year).benefit_groups.first
      expect(benefit_group.plan_option_kind).to eq nil
    end
  end

  describe "GET calc_employer_contributions" do
    let(:employer_profile){ double("EmployerProfile") }
    let(:reference_plan){ double("ReferencePlan", id: "id") }
    let(:plan_years){ [double("PlanYear")] }
    let(:benefit_groups){ [
      double(
        "BenefitGroup",
        monthly_employer_contribution_amount: 56.2,
        monthly_min_employee_cost: 200.21,
        monthly_max_employee_cost: 500.32
        )] }

      let(:plan){ double("Plan") }
      it "should calculate employer contributions" do
        allow(EmployerProfile).to receive(:find).with("id").and_return(employer_profile)
        allow(Plan).to receive(:find).and_return(reference_plan)
        allow(Forms::PlanYearForm).to receive(:build).and_return(plan_years.first)
        allow(plan_years.first).to receive(:benefit_groups).and_return(benefit_groups)
        allow(benefit_groups.first).to receive(:reference_plan=).and_return(plan)
        sign_in
        xhr :get, :calc_employer_contributions, employer_profile_id: "id", reference_plan_id: reference_plan.id
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET edit" do
      let(:plan_year) {FactoryGirl.build(:plan_year)}

      before :each do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in user
        allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
        allow(employer_profile).to receive(:find_plan_year).and_return(plan_year)
        allow(Organization).to receive(:valid_carrier_names).and_return({"id"=> "legal_name"})
      end

      context "when draft state" do
        before :each do
          get :edit, :employer_profile_id => employer_profile_id, id: plan_year_proxy.id
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it "should render the edit template" do
          expect(response).to render_template("edit")
        end

        it "should generate carriers" do
          expect(assigns(:carrier_names)).to eq({"id"=> "legal_name"})
          expect(assigns(:carriers_array)).to eq [["legal_name", "id"]]
        end
      end


      context "when publish pending state" do
        let(:warnings) { { primary_location: "primary location is outside washington dc" } }

        before :each do
          allow(plan_year).to receive(:publish_pending?).and_return(true)
          allow(plan_year).to receive(:withdraw_pending!)
          allow(plan_year).to receive(:is_application_valid?).and_return(false)
          allow(plan_year).to receive(:application_eligibility_warnings).and_return(warnings)
          get :edit, :employer_profile_id => employer_profile_id, id: plan_year_proxy.id
        end

        it "should set warnings flag" do
          expect(assigns(:just_a_warning)).to eq(true)
        end

        it "should set errors" do
          expect(plan_year.errors[:base]).to eq ["primary location is outside washington dc"]
        end
      end
    end


    describe "POST update" do
      let(:save_result) { false }
      let(:plan) {double(:where => [double(:_id => "test")] )}
      let(:benefit_group){ double(:reference_plan => double(:carrier_profile => double(:plans => plan)))}
      let(:plan_year) { double(:benefit_groups => [benefit_group], id: "id" ) }
      let(:relationship_benefits_attributes) {
        { "0" => {
         :relationship => "spouse",
         :premium_pct => "0.66",
         :employer_max_amt => "123.45",
         :offered => "false"
         } }
       }
       let(:benefit_groups_attributes) {
        { "0" => {
         :title => "My benefit group",
         :reference_plan_id => "rp_id",
         :effective_on_offset => "e_on_offset",
         :plan_option_kind => "single_plan",
         :employer_max_amt_in_cents => "2232",
         :relationship_benefits_attributes => relationship_benefits_attributes
         } }
       }

       let(:plan_year_params) {
        {
         :start_on => "01/01/2015",
         :end_on => "12/31/2015",
         :fte_count => "1",
         :pte_count => "3",
         :msp_count => "5",
         :open_enrollment_start_on => "12/01/2014",
         :open_enrollment_end_on => "12/15/2014",
         :benefit_groups_attributes => benefit_groups_attributes
       }
     }

     let(:plan_year_request_params) {
      {
       :start_on => "01/01/2015",
       :end_on => "12/31/2015",
       :fte_count => 1,
       :pte_count => 3,
       :msp_count => 5,
       :open_enrollment_start_on => "12/01/2014",
       :open_enrollment_end_on => "12/15/2014",
       :benefit_groups_attributes => benefit_groups_attributes
     }
   }
   let(:plan_years) {double}

   before :each do
    allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
    sign_in user
    allow(::Forms::PlanYearForm).to receive(:rebuild).with(plan_year, plan_year_params).and_return(plan_year)
    allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    allow(employer_profile).to receive(:plan_years).and_return(plan_years)
    allow(plan_years).to receive(:where).and_return([plan_year])
    allow(benefit_group).to receive(:elected_plans=).and_return("test")
    allow(benefit_group).to receive(:elected_dental_plans=).and_return("test")
    allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
    allow(benefit_group).to receive(:dental_plan_option_kind).and_return("single_carrier")
    allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return([])
    allow(benefit_group).to receive(:elected_dental_plans_by_option_kind).and_return([])
      #allow(benefit_group).to receive(:reference_plan_id).and_return(FactoryGirl.create(:plan).id)
      allow(benefit_group).to receive(:reference_plan_id).and_return(nil)
      allow(plan_year).to receive(:save).and_return(save_result)
      allow(Organization).to receive(:valid_carrier_names).and_return({"id"=> "legal_name"})
    end

    describe "with an invalid plan year" do
      before do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        post :update, :employer_profile_id => employer_profile_id, id: plan_year.id, :plan_year => plan_year_request_params
      end

      it "should render the new template" do
        expect(response).to have_http_status(:redirect)
      end

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should generate carriers" do
        expect(assigns(:carrier_names)).to eq({"id"=> 'legal_name'})
        expect(assigns(:carriers_array)).to eq [['legal_name', 'id']]
      end
    end

    describe "with a valid plan year" do
      let(:save_result) { true }
      before do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        post :update, :employer_profile_id => employer_profile_id, id: plan_year.id, :plan_year => plan_year_request_params
      end
      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should be a redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should has successful notice" do
        expect(flash[:notice]).to eq "Plan Year successfully saved."
      end
    end


    describe "with a valid plan year but not updateable" do
      let(:save_result) { true }
      before do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: false))
        post :update, :employer_profile_id => employer_profile_id, id: plan_year.id, :plan_year => plan_year_request_params
      end
      it "should assign the new plan year" do
        expect(assigns(:plan_year)).not_to eq plan_year
      end

      it "should be a redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should has successful notice" do

        expect(flash[:error]).to match(/Access not allowed/)
      end
    end


  end

  describe "POST create" do
    let(:save_result) { false }
    let(:plan) {double(:where => [double(:_id => "test")] )}
    let(:benefit_group){ double(:reference_plan => double(:carrier_profile => double(:plans => plan)), :default => false)}
    let(:plan_year) { double(:benefit_groups => [benefit_group] ) }
    let(:relationship_benefits_attributes) {
      { "0" => {
       :relationship => "spouse",
       :premium_pct => "0.66",
       :employer_max_amt => "123.45",
       :offered => "false"
       } }
     }
     let(:benefit_groups_attributes) {
      { "0" => {
       :title => "My benefit group",
       :reference_plan_id => "rp_id",
       :effective_on_offset => "e_on_offset",
       :plan_option_kind => "single_plan",
       :employer_max_amt_in_cents => "2232",
       :relationship_benefits_attributes => relationship_benefits_attributes
       } }
     }

     let(:plan_year_params) {
      {
       :start_on => "01/01/2015",
       :end_on => "12/31/2015",
       :fte_count => "1",
       :pte_count => "3",
       :msp_count => "5",
       :open_enrollment_start_on => "12/01/2014",
       :open_enrollment_end_on => "12/15/2014",
       :benefit_groups_attributes => benefit_groups_attributes
     }
   }

   let(:plan_year_request_params) {
    {
     :start_on => "01/01/2015",
     :end_on => "12/31/2015",
     :fte_count => 1,
     :pte_count => 3,
     :msp_count => 5,
     :open_enrollment_start_on => "12/01/2014",
     :open_enrollment_end_on => "12/15/2014",
     :benefit_groups_attributes => benefit_groups_attributes
   }
 }

 before :each do
  allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
  sign_in user
  allow(::Forms::PlanYearForm).to receive(:build).with(employer_profile, plan_year_params).and_return(plan_year)
  allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
  allow(employer_profile).to receive(:default_benefit_group).and_return(nil)
  allow(benefit_group).to receive(:elected_plans=).and_return("test")
  allow(benefit_group).to receive(:elected_dental_plans=).and_return("test")
  allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
  allow(benefit_group).to receive(:elected_plans_by_option_kind).and_return([])
  allow(benefit_group).to receive(:elected_dental_plans_by_option_kind).and_return([])
  allow(benefit_group).to receive(:dental_plan_option_kind).and_return("single_carrier")

  allow(benefit_group).to receive(:default=)
      #allow(benefit_group).to receive(:reference_plan_id).and_return(FactoryGirl.create(:plan).id)
      allow(benefit_group).to receive(:reference_plan_id).and_return(nil)
      allow(plan_year).to receive(:save).and_return(save_result)
      allow(Organization).to receive(:valid_carrier_names).and_return({'id' => "legal_name"})
      post :create, :employer_profile_id => employer_profile_id, :plan_year => plan_year_request_params
    end

    describe "with an invalid plan year" do
      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("new")
      end

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should generate carriers" do
        expect(assigns(:carrier_names)).to eq({'id' => 'legal_name'})
        expect(assigns(:carriers_array)).to eq [['legal_name', 'id']]
      end
    end

    describe "with a valid plan year" do
      let(:save_result) { true }

      it "should assign the new plan year" do
        expect(assigns(:plan_year)).to eq plan_year
      end

      it "should be a redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should has successful notice" do
        expect(flash[:notice]).to eq "Plan Year successfully created."
      end
    end
  end

  describe "GET recommend_dates" do
    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      xhr :get, :recommend_dates, employer_profile_id: employer_profile_id, start_on: "2015-05-10", format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET reference_plan_options" do
    let(:carrier_profile) { FactoryGirl.create(:carrier_profile) }
    before :each do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(Organization).to receive(:valid_carrier_names).and_return({'id' => "legal_name"})
    end

    it "should be a success" do
      xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get attributes" do
      xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', key: 'carrier_profile_id', format: :js
      expect(assigns(:kind)).to eq 'carrier'
      expect(assigns(:key)).to eq 'carrier_profile_id'
    end

    context "get plans" do
      it "should get empty" do
        xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'other', format: :js
        expect(assigns(:kind)).to eq 'other'
        expect(assigns(:plans)).to eq []
      end

      it "should get plans by metal_level" do
        xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'metal_level', key: 'gold', format: :js
        expect(assigns(:kind)).to eq 'metal_level'
        expect(assigns(:key)).to eq 'gold'
        expect(assigns(:plans)).to eq Plan.valid_shop_health_plans('metal_level', 'gold')
      end

      it "should get plans by carrier" do
        xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', key: carrier_profile.id.to_s, format: :js
        expect(assigns(:kind)).to eq 'carrier'
        expect(assigns(:key)).to eq carrier_profile.id.to_s
        expect(assigns(:plans)).to eq Plan.valid_shop_health_plans('carrier', carrier_profile.id.to_s)
      end
    end

    it "should generate carriers" do
      xhr :get, :reference_plan_options, employer_profile_id: employer_profile_id, kind: 'carrier', format: :js
      expect(assigns(:carrier_names)).to eq({'id' => "legal_name"})
      expect(assigns(:carriers_array)).to eq [['legal_name', 'id']]
    end
  end

  describe "POST publish" do
    let(:plan_year_id) { "plan_year_id"}
    let(:plan_year_proxy) { instance_double("PlanYear", publish!: double, may_publish?: true)}

    before :each do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(plan_year_proxy).to receive(:draft?).and_return(false)
      allow(plan_year_proxy).to receive(:publish_pending?).and_return(false)
      allow(plan_year_proxy).to receive(:application_errors)
    end

    context "plan year published sucessfully" do
      before :each do
        allow(plan_year_proxy).to receive(:published?).and_return(true)
        allow(plan_year_proxy).to receive(:assigned_census_employees_without_owner).and_return([double])
      end

      it "should redirect with success message" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:notice]).to eq "Plan Year successfully published."
      end
    end

    context "plan year published sucessfully but with warning" do
      before :each do
        allow(plan_year_proxy).to receive(:published?).and_return(true)
        allow(plan_year_proxy).to receive(:assigned_census_employees_without_owner).and_return([])
      end

      it "should redirect with success message" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:notice]).not_to eq "Plan Year successfully published."
        expect(flash[:error]).to eq "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?"
      end
    end

    context "plan year did not publish due to warnings" do
      before :each do
        allow(plan_year_proxy).to receive(:publish_pending?).and_return(true)
        allow(plan_year_proxy).to receive(:application_eligibility_warnings)
      end

      it "should be a render modal box with warnings" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        have_http_status(:success)
      end
    end

    context "plan year did not publish due to errors" do
      before :each do
        allow(plan_year_proxy).to receive(:draft?).and_return(true)
        allow(plan_year_proxy).to receive(:published?).and_return(false)
        allow(plan_year_proxy).to receive(:enrolling?).and_return(false)
        allow(plan_year_proxy).to receive(:renewing_published?).and_return(false)
        allow(plan_year_proxy).to receive(:renewing_enrolling?).and_return(false)
        allow(plan_year_proxy).to receive(:may_publish?).and_return(false)
        allow(plan_year_proxy).to receive(:application_errors).and_return({:values => []})
        allow(plan_year_proxy).to receive(:enrollment_period_errors).and_return([])
      end

      it "should redirect with errors" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:error]).to match(/Plan Year failed to publish/)
      end
    end

    context "plan year successfully published when renewing published" do
      before :each do
        allow(plan_year_proxy).to receive(:publish_pending?).and_return(false)
        allow(plan_year_proxy).to receive(:published?).and_return(false)
        allow(plan_year_proxy).to receive(:enrolling?).and_return(false)
        allow(plan_year_proxy).to receive(:renewing_published?).and_return(true)
        allow(plan_year_proxy).to receive(:renewing_enrolling?).and_return(false)
        allow(plan_year_proxy).to receive(:may_publish?).and_return(false)
        allow(plan_year_proxy).to receive(:assigned_census_employees_without_owner).and_return([double])
      end

      it "should redirect with success message" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:notice]).to match(/Plan Year successfully published./)
      end
    end

    context "plan year successfully published when enrolling" do
      before :each do
        allow(plan_year_proxy).to receive(:publish_pending?).and_return(false)
        allow(plan_year_proxy).to receive(:published?).and_return(false)
        allow(plan_year_proxy).to receive(:enrolling?).and_return(true)
        allow(plan_year_proxy).to receive(:renewing_published?).and_return(false)
        allow(plan_year_proxy).to receive(:renewing_enrolling?).and_return(false)
        allow(plan_year_proxy).to receive(:may_publish?).and_return(false)
        allow(plan_year_proxy).to receive(:assigned_census_employees_without_owner).and_return([double])
      end

      it "should redirect with success message" do
        xhr :post, :publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
        expect(flash[:notice]).to match(/Plan Year successfully published./)
      end
    end
  end

  describe "POST force publish" do
    let(:plan_year_id) { "plan_year_id"}
    let(:plan_year_proxy) { instance_double("PlanYear", publish!: double)}

    before :each do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(plan_year_proxy).to receive(:force_publish!)
      post :force_publish, employer_profile_id: employer_profile_id, plan_year_id: plan_year_id
    end

    it "should redirect" do
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET search_reference_plan" do
    let(:plan) {FactoryGirl.create(:plan)}
    before :each do
      sign_in
      xhr :get, :search_reference_plan, employer_profile_id: employer_profile_id, location_id: "test", reference_plan_id: plan.id, start_on: "2015-10-01", format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should be get location_id" do
      expect(assigns(:location_id)).to eq "test"
    end

    it "should be get plan" do
      expect(assigns(:plan)).to eq plan
    end
  end

  describe "GET employee_costs" do
    let(:plan_year){ double }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:census_employee) { FactoryGirl.build(:census_employee) }
    let(:census_employees) { double }

    before do
      @employer_profile = FactoryGirl.create(:employer_profile)
      @reference_plan = benefit_group.reference_plan
      Caches::PlanDetails.load_record_cache!
      @census_employees = [census_employee, census_employee]
    end

    it "should calculate employer contributions" do
      allow(EmployerProfile).to receive(:find).with(@employer_profile.id).and_return(@employer_profile)
      allow(Forms::PlanYearForm).to receive(:build).and_return(plan_year)
      allow(plan_year).to receive(:benefit_groups).and_return(benefit_group.to_a)
      allow(@employer_profile).to receive(:census_employees).and_return(census_employees)
      allow(census_employees).to receive(:active).and_return(@census_employees)
      allow(plan_year).to receive(:employer_profile).and_return(@employer_profile)
      sign_in
      xhr :get, :employee_costs, employer_profile_id: @employer_profile.id, reference_plan_id: @reference_plan.id, coverage_type: '.health'

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST make_default_benefit_group", dbclean: :after_each do
    context "when plan year is invalid" do
      let(:entity_kind)     { "partnership" }
      let(:bad_entity_kind) { "fraternity" }
      let(:entity_kind_error_message) { "#{bad_entity_kind} is not a valid business entity kind" }

      let(:address)  { Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:email  )  { Email.new(kind: "work", address: "info@sailaway.org") }

      let(:office_location) do
        OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
          )
      end

      let(:organization) { Organization.create(
        legal_name: "Sail Adventures, Inc",
        dba: "Sail Away",
        fein: "001223333",
        office_locations: [office_location]
        )
      }

      let(:valid_params)  do {
        organization: organization,
        entity_kind: entity_kind
        }
      end

      let(:default_benefit_group)     { FactoryGirl.build(:benefit_group, default: true)}
      let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
      let(:plan_year)         do
        py = FactoryGirl.build(:plan_year, benefit_groups: [default_benefit_group, benefit_group])
        py.open_enrollment_end_on = py.open_enrollment_start_on - 1.day
        py
      end
      let!(:employer_profile)  { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }

      let(:new_benefit_group)     { FactoryGirl.build(:benefit_group)}
      let(:new_plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [new_benefit_group]) }
      let!(:employer_profile1)  { EmployerProfile.new(**valid_params, plan_years: [plan_year, new_plan_year]) }

      before do
        employer_profile.save(:validate => false)
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in user
      end

      it "should log the validation error" do
        expect(subject).to receive(:log)
        begin
          post :make_default_benefit_group, employer_profile_id: employer_profile.id.to_s, plan_year_id: plan_year.id.to_s, benefit_group_id: benefit_group.id.to_s, format: :js
        rescue
        end
      end

      it "should raise the error" do
        expect do
          post :make_default_benefit_group, employer_profile_id: employer_profile.id.to_s, plan_year_id: plan_year.id.to_s, benefit_group_id: benefit_group.id.to_s, format: :js
        end.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "POST make_default_benefit_group", dbclean: :after_each do

    let(:entity_kind)     { "partnership" }
    let(:bad_entity_kind) { "fraternity" }
    let(:entity_kind_error_message) { "#{bad_entity_kind} is not a valid business entity kind" }

    let(:address)  { Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:email  )  { Email.new(kind: "work", address: "info@sailaway.org") }

    let(:office_location) do
      OfficeLocation.new(
        is_primary: true,
        address: address,
        phone: phone
        )
    end

    let(:organization) { Organization.create(
      legal_name: "Sail Adventures, Inc",
      dba: "Sail Away",
      fein: "001223333",
      office_locations: [office_location]
      )
    }

    let(:valid_params)  do {
      organization: organization,
      entity_kind: entity_kind
      }
    end

    let(:default_benefit_group)     { FactoryGirl.build(:benefit_group, default: true)}
    let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [default_benefit_group, benefit_group]) }
    let!(:employer_profile)  { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }

    let(:new_benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:new_plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [new_benefit_group]) }
    let!(:employer_profile1)  { EmployerProfile.new(**valid_params, plan_years: [plan_year, new_plan_year]) }

    context 'when same plan year' do
      before do
        employer_profile.save(:validate => false)
      end

      it "should calculate employer contributions" do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in user
        xhr :post, :make_default_benefit_group, employer_profile_id: employer_profile.id.to_s, plan_year_id: plan_year.id.to_s, benefit_group_id: benefit_group.id.to_s, format: :js
        default_benefit_groups = employer_profile.reload.plan_years.first.benefit_groups.select{|bg| bg.default }
        expect(default_benefit_groups.count).to eq 1
        expect(default_benefit_groups.first.id).to eq benefit_group.id
        expect(response).to have_http_status(:success)
      end
    end

    context 'when multiple plan years present' do
      before do
        employer_profile1.save(:validate => false)
      end

      it "should calculate employer contributions" do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in user
        xhr :post, :make_default_benefit_group, employer_profile_id: employer_profile1.id, plan_year_id: new_plan_year.id, benefit_group_id: new_benefit_group.id.to_s, format: :js
        employer_profile1.reload
        plan_year1 = employer_profile1.plan_years.where(id: plan_year.id).first
        expect(plan_year1.benefit_groups.select{|bg| bg.default}).to be_empty

        plan_year2 = employer_profile1.plan_years.where(id: new_plan_year.id).first
        expect(plan_year2.benefit_groups.select{|bg| bg.default}.count).to eq(1)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
