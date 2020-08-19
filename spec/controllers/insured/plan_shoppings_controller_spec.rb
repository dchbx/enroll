require 'rails_helper'

RSpec.describe Insured::PlanShoppingsController, :type => :controller, dbclean: :after_each do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    DatabaseCleaner.clean
  end

  describe ".sort_by_standard_plans", dbclean: :after_each do
    context "width standard plan present" do
      let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
      let(:family) { FactoryGirl.build_stubbed(:family, :with_primary_family_member, person: person )}
      let(:application) { FactoryGirl.create(:application, family: family) }
      let(:person) { FactoryGirl.build_stubbed(:person) }
      let(:user) { FactoryGirl.build_stubbed(:user, person: person) }
      let(:hbx_enrollment_one) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }
      let(:benefit_group) { FactoryGirl.build_stubbed(:benefit_group) }

      before :each do
        sign_in user
        allow(person).to receive_message_chain("primary_family.enrolled_hbx_enrollments").and_return([hbx_enrollment_one])
        allow(person.primary_family).to receive(:active_approved_application).and_return(application)
        allow(person.primary_family).to receive(:active_household).and_return(household)
      end

      @controller = Insured::PlanShoppingsController.new

      let(:plan1) { FactoryGirl.build(:plan) }
      let(:plan2) { FactoryGirl.build(:plan, is_standard_plan: true ) }
      let(:plans) {[PlanCostDecorator.new(plan1, hbx_enrollment_one, benefit_group, benefit_group.reference_plan_id), PlanCostDecorator.new(plan2, hbx_enrollment_one, benefit_group, benefit_group.reference_plan_id)]}

      it "should display the standard plan first" do
        expect(@controller.send(:sort_by_standard_plans,plans) ).to eq [plan2, plan1]
      end
    end
  end

  describe "not eligible for cost sharing or aptc / normal user", dbclean: :after_each do
    let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
    let(:family) { FactoryGirl.build_stubbed(:family, :with_primary_family_member, person: person )}
    let(:application) { FactoryGirl.create(:application, family: family) }
    let(:person) { FactoryGirl.build_stubbed(:person) }
    let(:user) { FactoryGirl.build_stubbed(:user, person: person) }
    let(:hbx_enrollment_one) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }

    context "GET plans" do
      before :each do
        allow(hbx_enrollment_one).to receive(:is_shop?).and_return(false)
        allow(hbx_enrollment_one).to receive(:decorated_elected_plans).and_return([])
        allow(person).to receive(:primary_family).and_return(family)
        allow(family).to receive(:active_household).and_return(household)
        allow(family).to receive(:currently_enrolled_plans_ids).and_return([])
        allow(family).to receive(:currently_enrolled_plans).and_return([])
        allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment_one)
        sign_in user
        allow(person).to receive_message_chain("primary_family.enrolled_hbx_enrollments").and_return([hbx_enrollment_one])
        allow(person.primary_family).to receive(:active_approved_application).and_return(application)
      end

      it "returns http success" do
        allow(person).to receive(:consumer_role).and_return nil
        allow(person).to receive(:employee_roles).and_return []
        xhr :get, :plans, id: "hbx_id", family_member_ids: [], market_kind: 'individual', format: :js
        expect(response).to have_http_status(:success)
      end
    end

    describe "Eligibility determined and not_csr_100 user" do
      let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
      let(:family_member_ids) {family.family_members.map(&:id)}
      let!(:person) { FactoryGirl.create(:person,  :with_consumer_role) }
      let!(:tax_household) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
      let(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household)}

      context "GET plans" do
        before :each do
          allow(hbx_enrollment_one).to receive(:is_shop?).and_return(false)
          allow(hbx_enrollment_one).to receive(:decorated_elected_plans).and_return([])
          allow(person).to receive(:primary_family).and_return(family)
          allow(family).to receive(:active_household).and_return(household)
          allow(family).to receive(:currently_enrolled_plans).and_return([])
          allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment_one)
          sign_in user
        end

        it "returns http success" do
          tax_household.eligibility_determinations = [eligibility_determination]
          person.primary_family.latest_household.tax_households << tax_household
          xhr :get, :plans, id: "hbx_id", family_member_ids: family_member_ids, format: :js
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  let(:plan) { double("Plan", id: "plan_id", coverage_kind: 'health', carrier_profile_id: 'carrier_profile_id') }
  let(:hbx_enrollment) { double("HbxEnrollment", id: "hbx_id", coverage_year: TimeKeeper.date_of_record.year, effective_on: double("effective_on", year: double), enrollment_kind: "open_enrollment") }
  let(:household){ double("Household") }
  let(:family){ double("Family") }
  let(:family_member){ double("FamilyMember", dob: 28.years.ago) }
  let(:family_members){ [family_member, family_member] }
  let(:benefit_group) {double("BenefitGroup", is_congress: false)}
  let(:reference_plan) {double("Plan")}
  let(:usermailer) {double("UserMailer")}
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:employee_role) { EmployeeRole.new }
  let(:household) {double("Household", hbx_enrollments: hbx_enrollments)}
  let(:hbx_enrollments) {double("HbxEnrollment")}

  context "POST checkout" do
    before do
      allow(Plan).to receive(:find).with("plan_id").and_return(plan)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:plan=).with(plan).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return false
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:may_select_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:select_coverage!).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(UserMailer).to receive(:plan_shopping_completed).and_return(usermailer)
      allow(usermailer).to receive(:deliver_now).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record + 10.days)
      allow(hbx_enrollment).to receive(:update_current).and_return(true)
      allow(hbx_enrollment).to receive(:inactive_related_hbxs).and_return(true)
      allow(hbx_enrollment).to receive(:inactive_pre_hbx).and_return true
      sign_in user
    end

    it "should get person" do
      post :checkout, id: "hbx_id", plan_id: "plan_id"
      expect(assigns(:person)).to eq person
    end

    it "returns http success" do
      post :checkout, id: "hbx_id", plan_id: "plan_id"
      expect(response).to have_http_status(:redirect)
    end

    it "should delete pre_hbx_enrollment_id session" do
      session[:pre_hbx_enrollment_id] = "123"
      post :checkout, id: "hbx_id", plan_id: "plan_id"
      expect(response).to have_http_status(:redirect)
      expect(session[:pre_hbx_enrollment_id]).to eq nil
    end

    context "employee hire_on date greater than enrollment date" do
      it "fails" do
        post :checkout, id: "hbx_id", plan_id: "plan_id"
        expect(flash[:error]).to include("You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance")
      end
    end

    context "hbx_enrollment can not select_coverage" do
      let(:errors) { double }
      before :each do
        request.env["HTTP_REFERER"] = "/home"
        allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record - 10.days)
        allow(hbx_enrollment).to receive(:can_select_coverage?).and_return false
        allow(hbx_enrollment).to receive(:errors).and_return(errors)
        allow(errors).to receive(:full_messages).and_return("You can not keep an existing plan which belongs to previous plan year")
      end

      it "should redirect" do
        post :checkout, id: "hbx_id", plan_id: "plan_id"
        expect(response).to have_http_status(:redirect)
      end

      it "should get flash" do
        post :checkout, id: "hbx_id", plan_id: "plan_id"
        expect(flash[:error]).to include("You can not keep an existing plan which belongs to previous plan year")
      end
    end
  end

  context "GET receipt" do
    let(:user) { double("User") }
    let(:enrollment) { double("HbxEnrollment", effective_on: double("effective_on", year: double), applied_aptc_amount: 0) }
    let(:plan) { double("Plan") }
    let(:benefit_group) { double("BenefitGroup", is_congress: false) }
    let(:reference_plan) { double("Plan") }
    let(:employee_role) { double("EmployeeRole") }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let (:individual_market_transition) { double ("IndividualMarketTransition") }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(enrollment)
      allow(enrollment).to receive(:is_shop?).and_return(false)
      allow(enrollment).to receive(:plan).and_return(plan)
      allow(enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(enrollment).to receive(:employee_role).and_return(employee_role)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(enrollment).to receive(:employee_role).and_return(double)
      allow(enrollment).to receive(:build_plan_premium).and_return(true)
      allow(enrollment).to receive(:ee_plan_selection_confirmation_sep_new_hire).and_return(true)
      allow(enrollment).to receive(:mid_year_plan_change_notice).and_return(true)
      allow(person).to receive(:current_individual_market_transition).and_return(individual_market_transition)
      allow(individual_market_transition).to receive(:role_type).and_return("consumer")
    end

    it "returns http success" do
      sign_in(user)
      get :receipt, id: "id"
      expect(response).to have_http_status(:success)
    end

    it "should get employer_profile" do
      allow(enrollment).to receive(:is_shop?).and_return(true)
      allow(enrollment).to receive(:coverage_kind).and_return('health')
      allow(enrollment).to receive(:employer_profile).and_return(employer_profile)
      sign_in(user)
      get :receipt, id: "id"
      expect(assigns(:employer_profile)).to eq employer_profile
    end
  end

  context "GET thankyou" do
    let(:enrollment) { double("HbxEnrollment", effective_on: double("effective_on", year: double)) }
    let(:plan) { double("Plan") }
    let(:benefit_group) { double("BenefitGroup", is_congress: false) }
    let(:reference_plan) { double("Plan") }
    let(:family) { double("Family") }
    let(:plan_year) { double("PlanYear") }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let (:individual_market_transition) { double ("IndividualMarketTransition") }

    before do
      allow(family).to receive(:application_in_progress).and_return(false)
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(enrollment)
      allow(Plan).to receive(:find).with("plan_id").and_return(plan)
      allow(enrollment).to receive(:plan).and_return(plan)
      allow(enrollment).to receive(:is_shop?).and_return(false)
      allow(enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(person).to receive(:primary_family).and_return(family)
      allow(enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(enrollment).to receive(:employee_role).and_return(double)
      allow(benefit_group).to receive(:plan_year).and_return(plan_year)
      allow(plan_year).to receive(:is_eligible_to_enroll?).and_return(true)
      allow(enrollment).to receive(:is_special_enrollment?).and_return false
      allow(enrollment).to receive(:can_select_coverage?).and_return(true)
      allow(enrollment).to receive(:build_plan_premium).and_return(true)
      allow(enrollment).to receive(:set_special_enrollment_period).and_return(true)
      allow(enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
      allow(person).to receive(:current_individual_market_transition).and_return(individual_market_transition)
      allow(individual_market_transition).to receive(:role_type).and_return(nil)
    end

    it "returns http success" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(response).to have_http_status(:success)
    end

     it "when enrollment has change plan" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id", change_plan: "rspec"
      expect(assigns(:change_plan)).to eq "rspec"
    end

    it "when enrollment does not have change plan" do
      sign_in(user)
      allow(enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:change_plan)).to eq "change_plan"
    end

    it "should be enrollable" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:enrollable)).to be_truthy
    end

    it "When enrollment kind receives" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id", enrollment_kind: "shop"
      expect(assigns(:enrollment_kind)).to eq "shop"
    end

    it "when is_special_enrollment " do
      sign_in(user)
      allow(enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:enrollment_kind)).to eq "sep"
    end

    it "when no special_enrollment" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:enrollment_kind)).to eq ""
    end


    it "should be waivable" do
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:waivable)).to be_truthy
    end

    it "should get employer_profile" do
      allow(enrollment).to receive(:is_shop?).and_return(true)
      allow(enrollment).to receive(:coverage_kind).and_return('health')
      allow(enrollment).to receive(:employer_profile).and_return(employer_profile)
      sign_in(user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(assigns(:employer_profile)).to eq employer_profile
    end

    it "returns http success as BROKER" do
      person = create(:person)
      transition = FactoryGirl.build(:individual_market_transition, :resident)
      person.individual_market_transitions << transition
      f=FactoryGirl.create(:family,:family_members=>[{:is_primary_applicant=>true, :is_active=>true, :person_id => person.id}])
      current_broker_user = FactoryGirl.create(:user, :roles => ['broker_agency_staff'],
        :person => person )
      current_broker_user.person.broker_role = BrokerRole.new({:broker_agency_profile_id => 99})
      allow(session).to receive(:[]).and_return(person.id.to_s)
      sign_in(current_broker_user)
      get :thankyou, id: "id", plan_id: "plan_id"
      expect(response).to have_http_status(:success)
    end

    context "when not eligible to complete shopping" do
      before do
        allow(enrollment).to receive(:can_complete_shopping?).and_return(false)
      end

      it "should not be enrollable" do
        sign_in(user)
        get :thankyou, id: "id", plan_id: "plan_id"
        expect(assigns(:enrollable)).to be_falsey
      end

      it "should not be waivable" do
        sign_in(user)
        get :thankyou, id: "id", plan_id: "plan_id"
        expect(assigns(:waivable)).to be_falsey
      end

      it "should update session" do
        sign_in(user)
        get :thankyou, id: "id", plan_id: "plan_id", elected_aptc: "50"
        expect(session[:elected_aptc]).to eq 50
      end
    end

    context "for qualify_qle_notice" do
      it "should get error msg" do
        allow(enrollment).to receive(:can_select_coverage?).and_return false
        sign_in(user)
        get :thankyou, id: "id", plan_id: "plan_id"
        expect(flash[:error]).to include("In order to purchase benefit coverage, you must be in either an Open Enrollment or Special Enrollment period. ")
      end

      it "should not get error msg" do
        allow(enrollment).to receive(:can_select_coverage?).and_return true
        sign_in(user)
        get :thankyou, id: "id", plan_id: "plan_id"
        expect(flash[:error]).to eq nil
      end
    end
  end

  context "GET print_waiver" do
    let(:notice_event) {"employee_waiver_confirmation"}
    let(:person) { FactoryGirl.create(:person, :with_employee_role) }
    let(:parent_enrollment){ FactoryGirl.create(:hbx_enrollment, household: family.active_household, employee_role_id: employee_role.id) }
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, predecessor_enrollment_id: parent_enrollment.id, employee_role_id: employee_role.id, aasm_state: 'inactive') }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:user) { FactoryGirl.build_stubbed(:user, person: person) }

    before do
      sign_in user
      get :print_waiver, id: enrollment.id
    end

    it "should be success" do
      expect(response).to have_http_status(:success)
    end

    it "should set hbx enrollment instance variable" do
      expect(assigns(:hbx_enrollment)).to eq enrollment
    end

    it "should trigger notice with predecessor_enrollment_id" do
      allow(controller).to receive(:trigger_notice_observer).with(parent_enrollment.employee_role, parent_enrollment, notice_event)
    end
  end

  context "POST terminate" do
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment,
      :with_enrollment_members,
      :enrollment_members => family.family_members,
      :household => family.active_household,
      :aasm_state => "coverage_selected",
      :benefit_group_id => benefit_group.id,
      :benefit_group_assignment_id => benefit_group_assignment.id,
      :employee_role_id => employee_role.id,
      :effective_on => coverage_end_on - 1.day)}

    let!(:waiver_enrollment) { FactoryGirl.create(:hbx_enrollment,
      :aasm_state => 'inactive',
      :household => family.active_household,
      :benefit_group_id => benefit_group.id,
      :benefit_group_assignment_id => benefit_group_assignment.id,
      :employee_role_id => employee_role.id)}

    let(:sep) { FactoryGirl.create :special_enrollment_period, family: family, qle_on: TimeKeeper.date_of_record.last_month.end_of_month }
    let!(:terminate_reason) { "terminate_reason" }
    let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'enrolling')}
    let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let!(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:person) { family.person }
    let!(:employee_role) { FactoryGirl.create(:employee_role, census_employee_id: census_employee.id, person: person, employer_profile_id: employer_profile.id)}
    let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment]) }
    let!(:coverage_end_on) { TimeKeeper.date_of_record.last_month.end_of_month }

    before do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(enrollment)
      allow(enrollment).to receive(:may_schedule_coverage_termination?).and_return(true)
      allow(enrollment).to receive(:schedule_coverage_termination!).and_return(true)
      allow(family).to receive(:earliest_effective_shop_sep).and_return sep
      allow(enrollment).to receive(:terminate_reason).and_return("terminate_reason")
      allow(person).to receive(:primary_family).and_return(Family.new)
      allow(waiver_enrollment).to receive(:parent_enrollment).and_return(enrollment)
      request.env["HTTP_REFERER"] = terminate_insured_plan_shopping_url(1)
      sign_in user
    end

    it "returns http success" do
      post :terminate, id: "hbx_id"
      expect(response).to be_redirect
    end

    it "goes back" do
      allow(enrollment).to receive(:may_schedule_coverage_termination?).and_return(false)
      allow(enrollment).to receive(:may_terminate_coverage?).and_return(false)
      post :terminate, id: "hbx_id"
      expect(response).to redirect_to(:back)
    end

    it "should record terminated_on date when termination of hbx_enrollment" do
      expect(enrollment.terminated_on).to eq nil
      post :terminate, id: "hbx_id", terminate_reason: terminate_reason
      enrollment.reload
      expect(enrollment.terminated_on).to eq coverage_end_on
      expect(response).to be_redirect
    end

    it "should create a new inactive enrollment" do
      post :terminate, id: "hbx_id", terminate_reason: terminate_reason
      enrollment.reload
      expect(enrollment.terminate_reason).to eq terminate_reason
    end
  end

  context "POST waive" do
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:person) { family.person }
    let!(:employee_role) { FactoryGirl.create(:employee_role, person: person)}
    let!(:parent_enrollment) { FactoryGirl.create(:hbx_enrollment, employee_role_id: employee_role.id, household: family.active_household, aasm_state: 'coverage_terminated') }

    before :each do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:may_waive_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:waive_enrollment).and_return(true)
      allow(hbx_enrollment).to receive(:shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:parent_enrollment).and_return(parent_enrollment)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      sign_in user
    end

    it "should get success flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:waive_coverage).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("waiver").and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get success flash mesage when enrollment is terminated" do
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("waiver").and_return(true)
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get failure flash message" do
      allow(hbx_enrollment).to receive(:waiver_reason=).with("waiver").and_return(false)
      allow(hbx_enrollment).to receive(:valid?).and_return(false)
      allow(hbx_enrollment).to receive(:inactive?).and_return(false)
      post :waive, id: "hbx_id", waiver_reason: "waiver"
      expect(flash[:alert]).to eq "Waive Coverage Failed"
      expect(response).to be_redirect
    end
  end

  context "waived_enrollment coverage kind" do
    let!(:hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, household: family.active_household, :aasm_state => "coverage_selected", :benefit_group_id => benefit_group.id, benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id: employee_role.id)
    }
    let(:sep) { FactoryGirl.create :special_enrollment_period, family: family, qle_on: TimeKeeper.date_of_record.last_month.end_of_month }
    let!(:waiver_reason) { "waiver_reason" }
    let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'enrolling')}
    let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let!(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:person) { family.person }
    let!(:employee_role) { FactoryGirl.create(:employee_role, census_employee_id: census_employee.id, person: person, employer_profile_id: employer_profile.id)}
    let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment]) }

    before :each do
      allow(HbxEnrollment).to receive(:find).with(hbx_enrollment.id).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:shopping?).and_return(false)
      sign_in user
    end

    it "waived enrollment coverage kind should be dental as waiving hbx_enrollment kind is dental" do
      hbx_enrollment.coverage_kind='dental'
      hbx_enrollment.save
      post :waive, id: hbx_enrollment.id, waiver_reason: waiver_reason
      waived_enrollment = employee_role.person.primary_family.enrollments.where(predecessor_enrollment_id: hbx_enrollment.id).first
      expect(waived_enrollment.coverage_kind).to eq 'dental'
    end

    it "waived enrollment coverage kind should be health as waiving hbx_enrollment kind is health" do
      expect(hbx_enrollment.coverage_kind).to eq 'health'
      post :waive, id: hbx_enrollment.id, waiver_reason: waiver_reason
      waived_enrollment = employee_role.person.primary_family.enrollments.where(predecessor_enrollment_id: hbx_enrollment.id).first
      expect(waived_enrollment.coverage_kind).to eq 'health'
    end
  end

  context "GET show" do
    let(:plan1) {double("Plan1", id: '10', deductible: '$10', total_employee_cost: 1000, carrier_profile_id: '12345')}
    let(:plan2) {double("Plan2", id: '11', deductible: '$20', total_employee_cost: 2000, carrier_profile_id: '12346')}
    let(:plan3) {double("Plan3", id: '12', deductible: '$30', total_employee_cost: 3000, carrier_profile_id: '12347')}
    let(:plans) {[plan1, plan2, plan3]}
    let(:coverage_kind){"health"}
    let (:individual_market_transition) { double ("IndividualMarketTransition") }
    #let(:person) { FactoryGirl.create(:person, :with_family)}
    let(:consumer_person) { FactoryGirl.create(:person, :with_consumer_role) }
    #let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: consumer_person) }

    before :each do
      allow(family).to receive(:application_in_progress).and_return(false)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(hbx_enrollment).to receive(:household).and_return(household)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:kind).and_return("employer_sponsored")
      allow(hbx_enrollment).to receive(:consumer_role).and_return(consumer_person.consumer_role)
      allow(household).to receive(:family).and_return(family)
      allow(family).to receive(:family_members).and_return(family_members)
      allow(controller).to receive(:get_tax_households_from_family_members).and_return []
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      allow(plan1).to receive(:[]).with(:id)
      allow(plan2).to receive(:[]).with(:id)
      allow(plan3).to receive(:[]).with(:id)
      allow(benefit_group).to receive(:decorated_elected_plans).with(hbx_enrollment, coverage_kind).and_return(plans)
      allow(family).to receive(:currently_enrolled_plans_ids).and_return([])
      allow(family).to receive(:currently_enrolled_plans).and_return([])
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:effective_on).and_return(Date.new(2015))
      allow(hbx_enrollment).to receive(:family).and_return(family)
      allow(person).to receive(:current_individual_market_transition).and_return(individual_market_transition)
      allow(individual_market_transition).to receive(:role_type).and_return(nil)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)

      sign_in user
    end

    context "normal" do
      before :each do
        allow(plan3).to receive(:total_employee_cost).and_return(3333)
        allow(plan3).to receive(:deductible).and_return("$998")
        get :show, family_member_ids: [], id: "hbx_id", market_kind: "shop"
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should be waivable" do
        expect(assigns(:waivable)).to be_truthy
      end

      it "should get max_total_employee_cost" do
        expect(assigns(:max_total_employee_cost)).to eq 4000
      end

      it "should get max_deductible" do
        expect(assigns(:max_deductible)).to eq 1000
      end

      it "should get plans which order by premium" do
        expect(assigns(:plans)).to eq [plan1, plan2, plan3]
      end

      it "should get the checkbook_url" do
        expect(assigns(:dc_checkbook_url)).to eq "http://checkbook_url"
      end
    end

    context "when not eligible to complete shopping" do
      before do
        allow(plan3).to receive(:total_employee_cost).and_return(3333)
        allow(plan3).to receive(:deductible).and_return("$998")
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:primary_family).and_return(family)
        allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(false)
        get :show, family_member_ids: [], id: "hbx_id"
      end

      it "should not be waivable" do
        expect(assigns(:waivable)).to be_falsey
      end
    end

    context "when innormal total_employee_cost and deductible" do
      before :each do
        [plan1, plan2, plan3].each do |plan|
          allow(plan).to receive(:total_employee_cost).and_return(nil)
          allow(plan).to receive(:deductible).and_return(nil)
          allow(user).to receive(:person).and_return(person)
          allow(person).to receive(:primary_family).and_return(family)
          allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
        end
        get :show, family_member_ids: [], id: "hbx_id"
      end

      it "should get max_total_employee_cost and return 0" do
        expect(assigns(:max_total_employee_cost)).to eq 0
      end

      it "should get max_deductible and return 0" do
        expect(assigns(:max_deductible)).to eq 0
      end
    end

    context "when user has_active_consumer_role" do
      let(:tax_household) {double("TaxHousehold")}
      let(:family) { FactoryGirl.build(:individual_market_family) }
      let!(:person) { FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let!(:user)  { FactoryGirl.create(:user, person: person) }

      before do
        allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
        allow(hbx_enrollment).to receive(:is_coverall?).and_return(false)
        allow(hbx_enrollment).to receive(:decorated_elected_plans).and_return([])

        allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
        allow(person).to receive(:active_employee_roles).and_return []
        allow(person).to receive(:consumer_role).and_return nil
        allow(person).to receive(:employee_roles).and_return []

      end

      context "with tax_household" do
        before :each do
          allow(family).to receive(:latest_household).and_return(household)
          allow(household).to receive(:latest_active_tax_households_with_year).and_return tax_household
          allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
          allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
          allow(person).to receive(:active_employee_roles).and_return []
          allow(person).to receive(:consumer_role).and_return nil
          allow(hbx_enrollment).to receive(:kind).and_return 'individual'
          allow(controller).to receive(:get_tax_households_from_family_members).and_return [tax_household]
          get :show, family_member_ids: [], id: "hbx_id", market_kind: 'individual'
        end

        it "should get max_aptc" do
          expect(assigns(:max_aptc)).to eq 111
        end

        it "should get default selected_aptc_pct" do
          expect(assigns(:elected_aptc)).to eq 111*0.85
        end
      end

      context "without tax_household" do
        before :each do
          allow(household).to receive(:latest_active_tax_households_with_year).and_return nil
          allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
          allow(person).to receive(:active_employee_roles).and_return []
          allow(person).to receive(:consumer_role).and_return nil
          allow(person).to receive(:employee_roles).and_return []
          get :show, family_member_ids: [], id: "hbx_id", market_kind: 'individual'
        end

        it "should get max_aptc" do
          expect(session[:max_aptc]).to eq 0
        end

        it "should get default selected_aptc" do
          expect(session[:elected_aptc]).to eq 0
        end
      end

      context "without tax_household when has aptc session" do
        before :each do
          allow(household).to receive(:latest_active_tax_households_with_year).and_return nil
          allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
          allow(person).to receive(:active_employee_roles).and_return []
          session[:max_aptc] = 100
          session[:elected_aptc] = 80
          allow(person).to receive(:consumer_role).and_return nil
          allow(person).to receive(:employee_roles).and_return []
          get :show, family_member_ids: [], id: "hbx_id", market_kind: 'individual'
        end

        it "should get max_aptc" do
          expect(session[:max_aptc]).to eq 0
        end

        it "should get default selected_aptc" do
          expect(session[:elected_aptc]).to eq 0
        end
      end

      context "with tax_household and plan shopping in shop market" do
        before :each do
          allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
          allow(household).to receive(:latest_active_tax_households_with_year).and_return tax_household
          allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
          allow(hbx_enrollment).to receive(:coverage_kind).and_return 'health'
          allow(hbx_enrollment).to receive(:kind).and_return 'individual'
          allow(person).to receive(:consumer_role).and_return nil
          allow(person).to receive(:employee_roles).and_return []
          allow_any_instance_of(Services::CheckbookServices::PlanComparision).to receive(:generate_url).and_return("http://temp.url")
          get :show, family_member_ids: [], id: "hbx_id", market_kind: 'individual'
        end

        it "should get max_aptc" do
          expect(session[:max_aptc]).to eq 0
        end

        it "should get default selected_aptc_pct" do
          expect(session[:elected_aptc]).to eq 0
        end
      end
    end
  end

  describe "plan_selection_callback" do
    let(:coverage_kind){"health"} 
    let(:market_kind){"individual"}
    let(:hios_id){"77422DC0110002-01"}
    let(:person) { FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role) }
    let(:user)  { FactoryGirl.create(:user, person: person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:plan) { FactoryGirl.create(:plan) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: 'individual', effective_on: (TimeKeeper.date_of_record.beginning_of_month).to_date, plan_id: plan.id) }

    context "When a callback is received" do
      before do
        sign_in user
        allow(Plan).to receive(:where).and_return([plan])
        get :plan_selection_callback, id: hbx_enrollment.id , hios_id:  hios_id,market_kind: market_kind , coverage_kind: coverage_kind
      end

      it "should assign market kind and coverage_kind" do
        expect(assigns(:market_kind)).to be_truthy
        expect(assigns(:coverage_kind)).to be_truthy
      end
    end
  end

  describe ".build_same_plan_premiums", dbclean: :after_each do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:dob) { Date.new(1985, 4, 10) }
    let(:person) { FactoryGirl.create(:person, :with_family,  :with_consumer_role, dob: dob) }
    let(:family) { person.primary_family }
    let(:household) { family.active_household }
    let(:individual_plans) { FactoryGirl.create_list(:plan, 5, :with_premium_tables, market: 'individual') }
    let(:plan) { individual_plans.first }
    let!(:previous_hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, household: household, plan: plan, effective_on: TimeKeeper.date_of_record.beginning_of_year, kind: 'individual')
    }

    let!(:new_hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, household: household, plan: plan, effective_on: Date.new(TimeKeeper.date_of_record.year, 5, 1), kind: 'individual', aasm_state: 'shopping')
    }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.current_benefit_period }

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 4, 10))
      allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile)
      allow(benefit_coverage_period).to receive(:elected_plans_by_enrollment_members).and_return(individual_plans)
      allow(person).to receive(:consumer_role).and_return nil
      allow(person).to receive(:employee_roles).and_return []
      sign_in user
    end

    context "when plan is same as existing coverage plan" do
      let(:previous_age) {
        person.age_on(previous_hbx_enrollment.effective_on)
      }

      it "should calculate premium from previous enrollment effective date" do
        Caches::PlanDetails.load_record_cache!
        allow(person).to receive(:consumer_role).and_return nil
        allow(person).to receive(:employee_roles).and_return []
        xhr :get, :plans, id: new_hbx_enrollment.id, market_kind: 'individual', format: :js
        matching_plan = assigns(:plans).detect{|e| e.id == new_hbx_enrollment.plan_id }
        premium = plan.premium_tables.where(:age => previous_age).first.cost
        expect(matching_plan.total_premium).to eq premium
      end
    end

    context "When plan is different from existing coverage plan" do

      let(:current_age) {
        person.age_on(new_hbx_enrollment.effective_on)
      }

      it "should calculate premium from new enrollment effective date" do
        Caches::PlanDetails.load_record_cache!
        allow(person).to receive(:consumer_role).and_return nil
        allow(person).to receive(:employee_roles).and_return []
        xhr :get, :plans, id: new_hbx_enrollment.id, market_kind: 'individual', format: :js
        non_matching_plans = assigns(:plans).select{|e| e.id != new_hbx_enrollment.plan_id }
        premiums = non_matching_plans.collect{|plan| plan.premium_tables.where(:age => current_age).first.cost }
        expect(non_matching_plans.collect{|p| p.total_premium}).to eq premiums
      end
    end
  end

  describe "plan comparision for IVL", dbclean: :after_each do
    let!(:person100)                  { FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role) }
    let!(:user100)                    { FactoryGirl.create(:user, person: person100) }
    let!(:family100)                  { FactoryGirl.create(:family, :with_primary_family_member, person: person100) }
    let!(:plan1)                      { FactoryGirl.create(:plan) }
    let!(:hbx_enrollment100)          { FactoryGirl.create(:hbx_enrollment, household: family100.active_household, kind: 'individual', effective_on: (TimeKeeper.date_of_record.beginning_of_month).to_date, plan_id: plan1.id) }
    let!(:hbx_enrollment_member100)   { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family100.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record.beginning_of_month).to_date, hbx_enrollment: hbx_enrollment100, coverage_start_on: (TimeKeeper.date_of_record.beginning_of_month).to_date) }
    let!(:hbx_enrollment101)          { FactoryGirl.create(:hbx_enrollment, household: family100.active_household, kind: 'individual', aasm_state: "shopping", effective_on: (TimeKeeper.date_of_record.next_month.beginning_of_month).to_date) }
    let!(:hbx_enrollment_member101)   { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family100.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record.beginning_of_month).to_date, hbx_enrollment: hbx_enrollment101) }
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

    context "GET plans" do
      before :each do
        sign_in user100
      end

      it "should successfully include the existing enrollment's plan as the Plan comparision for IVL is based on both active_year and hios_id" do
        plan1.update_attributes!(hios_id: ("41842DC04000" + (plan1.hios_id.split("-")[0].split("").last(2).join("").to_i + 2).to_s + "-04"))
        xhr :get, :plans, id: hbx_enrollment101.id, market_kind: "individual", format: :js
        expect(assigns(:plans).map(&:id).include?(assigns(:enrolled_plans)[0].id)).to be_truthy
      end

      it "should not assign enrolled_plans as the plan doesn't have a similar hios_id" do
        xhr :get, :plans, id: hbx_enrollment101.id, format: :js
        expect(assigns(:enrolled_plans).present?).to be_falsey
      end
    end
  end
end
