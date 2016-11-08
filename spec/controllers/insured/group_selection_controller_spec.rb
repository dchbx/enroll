require 'rails_helper'

RSpec.describe Insured::GroupSelectionController, :type => :controller do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) { instance_double("User", :person => person) }
  let(:consumer_role) {FactoryGirl.create(:consumer_role)}
  let(:employee_role) {FactoryGirl.create(:employee_role)}
  let(:household) {double(:immediate_family_coverage_household=> coverage_household, :hbx_enrollments => hbx_enrollments)}
  let(:coverage_household) {double}
  let(:family) {Family.new}
  let(:hbx_enrollment) {HbxEnrollment.create}
  let(:hbx_enrollments) {double(:enrolled => [hbx_enrollment])}
  let(:hbx_profile) {FactoryGirl.create(:hbx_profile)}
  let(:benefit_package) { FactoryGirl.build(:benefit_package,
      benefit_coverage_period: hbx_profile.benefit_sponsorship.benefit_coverage_periods.first,
      title: "individual_health_benefits_2015",
      elected_premium_credit_strategy: "unassisted",
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
    ))}
    let(:bcp) { double }

  before do
    allow(Person).to receive(:find).and_return(person)
    allow(person).to receive(:primary_family).and_return(family)
    allow(family).to receive(:active_household).and_return(household)
    allow(person).to receive(:consumer_role).and_return(nil)
    allow(person).to receive(:consumer_role?).and_return(false)
    allow(user).to receive(:last_portal_visited).and_return('/')
  end

  context "GET new" do
    let(:census_employee) {FactoryGirl.build(:census_employee)}
    it "return http success" do
      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(response).to have_http_status(:success)
    end

    # it "returns to family home page when employee is not under open enrollment" do
    #   sign_in user
    #   employee_roles = [employee_role]
    #   allow(person).to receive(:employee_roles).and_return(employee_roles)
    #   allow(employee_roles).to receive(:detect).and_return(employee_role)
    #   allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
    #   get :new, person_id: person.id, employee_role_id: employee_role.id
    #   expect(response).to redirect_to(family_account_path)
    #   expect(flash[:alert]).to eq "You can only shop for plans during open enrollment."
    # end

    it "return blank change_plan" do
      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(assigns(:change_plan)).to eq ""
    end

    it "return change_plan" do
      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id, change_plan: "change"
      expect(assigns(:change_plan)).to eq "change"
    end

    it "should get person" do
      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(assigns(:person)).to eq person
    end

    it "should get hbx_enrollment when has active hbx_enrollments and in qle flow" do
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:shop_market).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:enrolled_and_renewing).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:effective_desc).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true

      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop'
      expect(assigns(:hbx_enrollment)).to eq hbx_enrollment
    end

    it "should get hbx_enrollment when has enrolled hbx_enrollments and in shop qle flow but user has both employee_role and consumer_role" do
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:shop_market).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:enrolled_and_renewing).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:effective_desc).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true

      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop', consumer_role_id: consumer_role.id
      expect(assigns(:hbx_enrollment)).to eq hbx_enrollment
    end

    it "should not get hbx_enrollment when has active hbx_enrollments and not in qle flow" do
      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id
      expect(assigns(:hbx_enrollment)).not_to eq hbx_enrollment
    end

    it "should disable individual market kind if selected market kind is shop in dual role SEP" do
      allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:shop_market).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:enrolled_and_renewing).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:effective_desc).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return true

      sign_in user
      get :new, person_id: person.id, employee_role_id: employee_role.id, change_plan: 'change_by_qle', market_kind: 'shop', consumer_role_id: consumer_role.id
      expect(assigns(:disable_market_kind)).to eq "individual"
    end

    context "individual" do
      let(:hbx_profile) {double(benefit_sponsorship: benefit_sponsorship)}
      let(:benefit_sponsorship) {double(benefit_coverage_periods: [benefit_coverage_period])}
      let(:benefit_coverage_period) {FactoryGirl.build(:benefit_coverage_period)}
      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(benefit_coverage_period).to receive(:benefit_packages).and_return [benefit_package]
        allow(benefit_coverage_period).to receive(:start_on).and_return double(year: 2015)
        allow(person).to receive(:has_active_consumer_role?).and_return true
        allow(person).to receive(:has_active_employee_role?).and_return false
        allow(HbxEnrollment).to receive(:find).and_return nil
        allow(HbxEnrollment).to receive(:calculate_effective_on_from).and_return TimeKeeper.date_of_record
      end

      it "should set session" do
        sign_in user
        get :new, person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: "123"
        expect(session[:pre_hbx_enrollment_id]).to eq "123"
      end

      it "should get new_effective_on" do
        sign_in user
        get :new, person_id: person.id, consumer_role_id: consumer_role.id, change_plan: "change", hbx_enrollment_id: "123"
        expect(assigns(:new_effective_on)).to eq TimeKeeper.date_of_record
      end
    end
  end

  context "GET terminate_selection" do
    it "return http success and render" do
      sign_in
      get :terminate_selection, person_id: person.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:terminate_selection)
    end
  end

  context "GET terminate_confirm" do
    it "return http success and render" do
      sign_in
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      get :terminate_confirm, person_id: person.id, hbx_enrollment_id: hbx_enrollment.id
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:terminate_confirm)
    end
  end

  context "POST terminate" do

    before do
      sign_in
      request.env["HTTP_REFERER"] = terminate_confirm_insured_group_selections_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
    end

    it "should redirect to family home if termination is possible" do
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:terminate_benefit)
      expect(hbx_enrollment).to receive(:propogate_terminate).with(Date.today)
      expect(hbx_enrollment.termination_submitted_on).to eq nil
      post :terminate, term_date: Date.today, hbx_enrollment_id: hbx_enrollment.id
      expect(hbx_enrollment.termination_submitted_on).to eq TimeKeeper.datetime_of_record
      expect(response).to redirect_to(family_account_path)
    end

    it "should redirect back if hbx enrollment can't be terminated" do
      post :terminate, term_date: Date.today, hbx_enrollment_id: hbx_enrollment.id
      expect(hbx_enrollment.may_terminate_coverage?).to be_falsey
      expect(response).to redirect_to(terminate_confirm_insured_group_selections_path(person_id: person.id, hbx_enrollment_id: hbx_enrollment.id))
    end

  end

  context "POST CREATE" do
    let(:family_member_ids) {{"0"=>"559366ca63686947784d8f01", "1"=>"559366ca63686947784e8f01", "2"=>"559366ca63686947784f8f01", "3"=>"559366ca6368694778508f01"}}
    let(:benefit_group) {FactoryGirl.create(:benefit_group)}
    let(:benefit_group_assignment) {double(update: true)}
    let(:employee_roles){ [double("EmployeeRole")] }
    before do
      allow(coverage_household).to receive(:household).and_return(household)
      allow(household).to receive(:new_hbx_enrollment_from).and_return(hbx_enrollment)
      allow(person).to receive(:employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:rebuild_members_by_coverage_household).with(coverage_household: coverage_household).and_return(true)
      allow(family).to receive(:latest_household).and_return(household)
      allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
      allow(hbx_enrollment).to receive(:inactive_related_hbxs).and_return(true)
      sign_in
    end

    it "should redirect" do
      user=FactoryGirl.create(:user, id: 99, person: person)
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, market_kind: 'shop', coverage_kind: 'health', enrollment_kind: ''))
    end

    it "with change_plan" do
      user = FactoryGirl.create(:user, id: 98, person: FactoryGirl.create(:person))
      sign_in user
      allow(hbx_enrollment).to receive(:save).and_return(true)
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, change_plan: 'change'
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_plan_shopping_path(id: hbx_enrollment.id, change_plan: 'change', coverage_kind: 'health', market_kind: 'shop', enrollment_kind: ''))
    end

    context "when keep_existing_plan" do
      let(:old_hbx) { HbxEnrollment.new }
      let(:special_enrollment) { FactoryGirl.build(:special_enrollment_period) }
      before :each do
        user = FactoryGirl.create(:user, person: FactoryGirl.create(:person))
        sign_in user
        allow(hbx_enrollment).to receive(:save).and_return(true)
        allow(hbx_enrollment).to receive(:plan=).and_return(true)
        allow(HbxEnrollment).to receive(:find).and_return old_hbx
        allow(old_hbx).to receive(:is_shop?).and_return true
        allow(old_hbx).to receive(:family).and_return family
        allow(family).to receive(:earliest_effective_shop_sep).and_return special_enrollment
        post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids, commit: 'Keep existing plan', change_plan: 'change', hbx_enrollment_id: old_hbx.id
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to(purchase_insured_families_path(change_plan:'change', coverage_kind: 'health', market_kind:'shop', hbx_enrollment_id: old_hbx.id))
      end

      it "should get special_enrollment_period_id" do
        expect(hbx_enrollment.special_enrollment_period_id).to eq special_enrollment.id
      end
    end

    it "should render group selection page if not valid" do
      user = FactoryGirl.create(:user, id: 96, person: FactoryGirl.create(:person))
      sign_in user
      allow(person).to receive(:employee_roles).and_return([employee_role])
      post :create, person_id: person.id, employee_role_id: employee_role.id, family_member_ids: family_member_ids
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq 'You must select the primary applicant to enroll in the healthcare plan'
      expect(response).to redirect_to(new_insured_group_selection_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', enrollment_kind: ''))
    end

    it "should render group selection page if without family_member_ids" do
      post :create, person_id: person.id, employee_role_id: employee_role.id
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq 'You must select at least one Eligible applicant to enroll in the healthcare plan'
      expect(response).to redirect_to(new_insured_group_selection_path(person_id: person.id, employee_role_id: employee_role.id, change_plan: '', market_kind: 'shop', enrollment_kind: ''))
    end
  end
end
