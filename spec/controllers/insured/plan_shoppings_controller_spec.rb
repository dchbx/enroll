require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Insured::PlanShoppingsController, :type => :controller, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person, :with_family)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
  let(:household){ family.active_household }
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
  let(:reference_plan) {double("Product")}
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id, product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments:[member_enrollment], product_cost_total:'')}
  let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                           family: household.family,
                                           household: household,
                                           hbx_enrollment_members: [hbx_enrollment_member],
                                           coverage_kind: "health",
                                           external_enrollment: false,
                                           sponsored_benefit_id: sponsored_benefit.id,
                                           rating_area_id: rating_area.id)
  }
  let(:benefit_group) { current_benefit_package }
  let(:usermailer) {double("UserMailer")}
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
  let!(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:cost_calculator) { HbxEnrollmentSponsoredCostCalculator.new(hbx_enrollment) }

  context "POST checkout", :dbclean => :around_each do
    before do
      allow(BenefitMarkets::Products::Product).to receive(:find).with("plan_id").and_return(product)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:product=).with(product).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return false
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(UserMailer).to receive(:plan_shopping_completed).and_return(usermailer)
      allow(usermailer).to receive(:deliver_now).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record + 10.days)

      sign_in user
    end

    it "should get person" do
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(assigns(:person)).to eq person
    end

    it "returns http success" do
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(response).to have_http_status(:redirect)
    end

    it "should delete pre_hbx_enrollment_id session" do
      session[:pre_hbx_enrollment_id] = "123"
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(response).to have_http_status(:redirect)
      expect(session[:pre_hbx_enrollment_id]).to eq nil
    end

    context "employee hire_on date greater than enrollment date" do
      it "fails" do
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
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
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
        expect(response).to have_http_status(:redirect)
      end

      it "should get flash" do
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
        expect(flash[:error]).to include("You can not keep an existing plan which belongs to previous plan year")
      end
    end
  end

  context "GET receipt", :dbclean => :around_each do
    let(:member_group) { double("MEMBERGROUP")}

    before do
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(hbx_enrollment).to receive(:build_plan_premium).and_return(true)
      allow(hbx_enrollment).to receive(:census_employee).and_return(census_employee)
      allow(subject).to receive(:employee_mid_year_plan_change).and_return(true)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(cost_calculator).to receive(:groups_for_products).with([product]).and_return([member_group])
    end

    it "returns http success" do
      sign_in(user)
      get :receipt, params: {id: "id"}
      expect(response).to have_http_status(:success)
    end

    it "should get employer_profile" do
      allow(hbx_enrollment).to receive(:employee_role_id).and_return(nil)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
      sign_in(user)
      get :receipt, params: {id: "id"}
      expect(assigns(:employer_profile)).to eq abc_profile
    end

    context "#send_receipt_emails" do
      it "should send send secure message to IVL person inbox" do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
        sign_in(user)
        expect(person.inbox.messages.count).to eq(1)
        get :receipt, params: {id: "id"}
        expect(person.inbox.messages.count).to eq(2)
        expect(person.inbox.messages.last.subject).to eq("Your Enrollment Confirmation")
      end

      it "should send send secure message to SHOP person inbox"do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
        sign_in(user)
        expect(person.inbox.messages.count).to eq(1)
        get :receipt, params: {id: "id"}
        expect(person.inbox.messages.count).to eq(2)
        expect(person.inbox.messages.last.subject).to eq("Your Enrollment Confirmation")
      end
    end
  end

  context "GET thankyou", :dbclean => :around_each do
    let(:member_group) { double("MEMBERGROUP")}

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      allow(BenefitMarkets::Products::Product).to receive(:find).with("plan_id").and_return(product)
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(person).to receive(:primary_family).and_return(family)
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(double)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return false
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:build_plan_premium).and_return(true)
      allow(hbx_enrollment).to receive(:set_special_enrollment_period).and_return(true)
      allow(hbx_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(cost_calculator).to receive(:groups_for_products).with([product]).and_return([member_group])
    end

    it "returns http success" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(response).to have_http_status(:success)
    end

    it "when enrollment has change plan" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id", change_plan: "rspec" }
      expect(assigns(:change_plan)).to eq "rspec"
    end

    it "when enrollment does not have change plan" do
      sign_in(user)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:change_plan)).to eq "change_plan"
    end

    it "should be enrollable" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:enrollable)).to be_truthy
    end

    it "When enrollment kind receives" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id", enrollment_kind: "shop" }
      expect(assigns(:enrollment_kind)).to eq "shop"
    end

    it "when is_special_enrollment " do
      sign_in(user)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:enrollment_kind)).to eq "sep"
    end

    it "when no special_enrollment" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:enrollment_kind)).to eq ""
    end

    it "should be waivable" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:waivable)).to be_truthy
    end

    it "should get employer_profile" do
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:employer_profile)).to eq abc_profile
    end

    it "returns http success as BROKER" do
      person = create(:person)
      f=FactoryBot.create(:family,:family_members=>[{:is_primary_applicant=>true, :is_active=>true, :person_id => person.id}])
      current_broker_user = FactoryBot.create(:user, :roles => ['broker_agency_staff'],
                                               :person => person )
      current_broker_user.person.broker_role = BrokerRole.new({:broker_agency_profile_id => 99})
      allow(session).to receive(:[]).and_return(person.id.to_s)
      sign_in(current_broker_user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(response).to have_http_status(:success)
    end

    context "when not eligible to complete shopping" do
      before do
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(false)
      end

      it "should not be enrollable" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id"}
        expect(assigns(:enrollable)).to be_falsey
      end

      it "should not be waivable" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id"}
        expect(assigns(:waivable)).to be_falsey
      end

      it "should update session" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id", elected_aptc: "50"}
        expect(session[:elected_aptc]).to eq 50
      end
    end

    # context "for qualify_qle_notice" do
    #   it "should get error msg" do
    #     allow(hbx_enrollment).to receive(:can_select_coverage?).and_return false
    #     sign_in(user)
    #     get :thankyou, id: "id", plan_id: "plan_id"
    #     expect(flash[:error]).to include("In order to purchase benefit coverage, you must be in either an Open Enrollment or Special Enrollment period. ")
    #   end
    #
    #   it "should not get error msg" do
    #     allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
    #     sign_in(user)
    #     get :thankyou, id: "id", plan_id: "plan_id"
    #     expect(flash[:error]).to eq nil
    #   end
    # end
  end

  context 'GET thankyou  - reset coverage dates', :dbclean => :around_each do

    let(:person) {FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, :person => person)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:year) {TimeKeeper.date_of_record.year}
    let(:effective_on) {Date.new(year, 3, 1)}
    let(:previous_enrollment_status) {'coverage_selected'}
    let(:terminated_on) {nil}
    let(:covered_individuals) {family.family_members}
    let(:newly_covered_individuals) {family.family_members}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_month}
    let(:qualifying_life_event_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let(:special_enrollment_period) do
      special_enrollment = person.primary_family.special_enrollment_periods.build({effective_on_kind: 'first_of_month'})
      special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
      special_enrollment.start_on = TimeKeeper.date_of_record.prev_day
      special_enrollment.end_on = TimeKeeper.date_of_record + 30.days
      special_enrollment.save
      special_enrollment
    end

    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        benefit_market_kind: :aca_individual,
                        application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end

    let!(:previous_coverage) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on.beginning_of_year,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product,
                        aasm_state: previous_enrollment_status,
                        terminated_on: terminated_on)
    end

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: newly_covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product)
    end

    it 'should update the member coverage start on for continuous coverage' do
      sign_in(user)
      get :thankyou, params: { id: hbx_enrollment.id, plan_id: product.id }
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq previous_coverage.hbx_enrollment_members.first.coverage_start_on
    end
  end

  context "GET print_waiver", :dbclean => :around_each do
    it "should return hbx_enrollment to print waiver" do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      sign_in(user)
      get :print_waiver, params: {id: "id"}
      expect(response).to have_http_status(:success)
    end
  end

  context "POST terminate", :dbclean => :around_each do
    let(:coverage_start_on) {TimeKeeper.date_of_record.last_month.beginning_of_month}
    let(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_product,
                        sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                        household: household,
                        family: household.family,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        coverage_kind: "health",
                        effective_on: coverage_start_on,
                        external_enrollment: false,
                        sponsored_benefit_id: sponsored_benefit.id,
                        rating_area_id: rating_area.id)
    end

    let(:waiver_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_product,
                        sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                        household: household,
                        family: household.family,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        coverage_kind: "health",
                        external_enrollment: false,
                        sponsored_benefit_id: sponsored_benefit.id,
                        predecessor_enrollment_id: hbx_enrollment.id,
                        rating_area_id: rating_area.id)
    end
    let(:coverage_end_on) {TimeKeeper.date_of_record.end_of_month}

    before do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:employee_role_id).and_return(employee_role.id)
      allow(person).to receive(:primary_family).and_return(family)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(waiver_enrollment).to receive(:parent_enrollment).and_return(hbx_enrollment)
      request.env["HTTP_REFERER"] = terminate_insured_plan_shopping_url(1)
      sign_in user
    end

    it "returns http success" do
      post :terminate, params: {id: "hbx_id"}
      expect(response).to be_redirect
    end

    it "goes back" do
      post :terminate, params: {id: "hbx_id"}
      expect(response).to have_http_status(:redirect)
    end

    it "should record termination submitted date on terminate of hbx_enrollment" do
      expect(hbx_enrollment.termination_submitted_on).to eq nil
      post :terminate, params: {id: "hbx_id", terminate_reason: "Because"}
      expect(hbx_enrollment.terminated_on).to eq coverage_end_on
      expect(hbx_enrollment.termination_submitted_on).to be_within(1.second).of TimeKeeper.datetime_of_record
      expect(response).to have_http_status(:redirect)
    end

    it "should create a new inactive enrollment" do
      post :terminate, params: {id: "hbx_id", terminate_reason: "Because"}
      hbx_enrollment.reload
      expect(hbx_enrollment.terminate_reason).to eq "Because"
    end

    context 'for terminate_date' do
      let(:terminate_date) { TimeKeeper.date_of_record.next_month.end_of_month }

      before do
        post :terminate, params: {id: 'hbx_id',
                                  terminate_reason: 'Because',
                                  terminate_date: terminate_date.to_s}
      end

      it 'terminated on date should be terminate_date' do
        expect(hbx_enrollment.terminated_on).to eq terminate_date
      end
    end
  end

  context "GET waive", :dbclean => :around_each do
    before :each do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:may_waive_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:waive_enrollment).and_return(true)
      allow(hbx_enrollment).to receive(:shopping?).and_return(true)
      sign_in user
    end

    it "should get success flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:waive_coverage).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get success flash mesage when enrollment is terminated" do
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end
    
    it "#post enrollment termination" do 
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      post :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get failure flash message" do
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(false)
      allow(hbx_enrollment).to receive(:valid?).and_return(false)
      allow(hbx_enrollment).to receive(:inactive?).and_return(false)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:alert]).to eq "Waive Coverage Failed"
      expect(response).to be_redirect
    end
  end

  context "GET show", :dbclean => :around_each do
    let(:product_1)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:product_2)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:product_3)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:products) {[hbx_enrollment.sponsored_benefit.reference_product]}
    let(:coverage_kind){"health"}
    let(:cost_calculator) { HbxEnrollmentSponsoredCostCalculator.new(hbx_enrollment) }
    let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:product_groups) { products }
    let(:family_group_enrollment) do
      BenefitSponsors::Enrollments::GroupEnrollment.new(
          member_enrollments: [],
          rate_schedule_date: '',
          coverage_start_on: '',
          previous_product: nil,
          product: products,
          rating_area: '',
          product_cost_total: ''
      )
    end
    let(:member_group) do
      ::BenefitSponsors::Members::MemberGroup.new(
          group_enrollment: [family_group_enrollment]
      )
    end
    let!(:update_sponsored_benefit) { sponsored_benefit.update_attributes(product_package_kind: "single_product") }

    before :each do
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:household).and_return(household)
      allow(family).to receive(:family_members).and_return(family_members)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
      allow(hbx_enrollment).to receive(:kind).and_return("employer_sponsored")
      allow(hbx_enrollment).to receive(:consumer_role).and_return(consumer_person.consumer_role)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:effective_on).and_return(Date.new(2015))
      allow(hbx_enrollment).to receive(:family).and_return(family)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(hbx_enrollment).to receive(:employee_role).and_return employee_role
      allow(cost_calculator).to receive(:groups_for_products).with(products).and_return(product_groups)
      allow_any_instance_of(Insured::PlanShoppingsController).to receive(:sort_member_groups).with(product_groups).and_return(member_group)
      allow(hbx_enrollment).to receive(:product).and_return(product_1)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      sign_in user
    end

    context "normal" do
      before :each do
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(true)
        get :show, params: {id: "hbx_id", market_kind: 'shop'}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should be waivable" do
        expect(assigns(:waivable)).to be_truthy
      end

      it "should get the checkbook_url" do
        expect(assigns(:dc_checkbook_url)).to eq "http://checkbook_url"
      end
    end

    context 'when market_kind is blank' do
      before do
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(true)
        get :show, params: {id: "hbx_id", market_kind: 'shop'}
      end

      it 'is successful' do
        expect(response).to have_http_status(:success)
      end
    end

    context "when not eligible to complete shopping" do
      let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments:[member_enrollment], product_cost_total:'')}

      before :each do
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(false)
        allow(user).to receive(:person).and_return(person)
        allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
        allow(person).to receive(:primary_family).and_return(family)
        allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(false)
        allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
        get :show, params: {id: "hbx_id"}
      end

      it "should not be waivable" do
        expect(assigns(:waivable)).to be_falsey
      end
    end

    if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
      context "when user has_active_consumer_role" do
        let(:tax_household) {double("TaxHousehold")}
        let(:family) { FactoryBot.build(:individual_market_family) }
        let(:person) {double("Person",primary_family: family, has_active_consumer_role?: true)}
        let(:user) {double("user",person: person)}

        before do
          allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
          allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
          allow(hbx_enrollment).to receive(:is_coverall?).and_return(false)
          allow(hbx_enrollment).to receive(:decorated_elected_plans).and_return([])
        end

        context "with tax_household" do
          before :each do
            allow(family).to receive(:latest_household).and_return(household)
            allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
            allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            allow(hbx_enrollment).to receive(:kind).and_return 'individual'
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(assigns(:max_aptc)).to eq 111
          # end
          #
          # it "should get default selected_aptc_pct" do
          #   expect(assigns(:elected_aptc)).to eq 111*0.85
          # end
        end

        context "without tax_household" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return nil
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end

        context "without tax_household when has aptc session" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return nil
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            session[:max_aptc] = 100
            session[:elected_aptc] = 80
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end

        context "with tax_household and plan shopping in shop market" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
            allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            allow(hbx_enrollment).to receive(:coverage_kind).and_return 'health'
            allow(hbx_enrollment).to receive(:kind).and_return 'shop'
            allow_any_instance_of(Services::CheckbookServices::PlanComparision).to receive(:generate_url).and_return("http://temp.url")
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc_pct" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end
      end
    end
  end

  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    describe "plan_selection_callback" do
      let(:coverage_kind){"health"}
      let(:market_kind){"individual"}
      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:user)  { FactoryBot.create(:user, person: person) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual) }
      let(:year) { product.application_period.min.year }
      let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, kind: 'individual', effective_on: TimeKeeper.date_of_record.beginning_of_month.to_date, product_id: product.id) }

      context "When a callback is received" do
        before do
          sign_in user
          get :plan_selection_callback, params: { id: hbx_enrollment.id, hios_id: product.hios_id, year: year, market_kind: market_kind, coverage_kind: coverage_kind }
        end

        it "should assign market kind and coverage_kind" do
          expect(assigns(:market_kind)).to be_truthy
          expect(assigns(:coverage_kind)).to be_truthy
        end
      end
    end
  end
end
