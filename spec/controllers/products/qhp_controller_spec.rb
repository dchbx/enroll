require 'rails_helper'

RSpec.describe Products::QhpController, :type => :controller do
  let(:user) { double("User", person: person) }
  let(:person) { double("Person", primary_family: family, is_consumer_role_active?: true)}
  let(:hbx_enrollment){double("HbxEnrollment", is_shop?: true, kind: "employer_sponsored", enrollment_kind: 'open_enrollment', plan: plan, coverage_kind: 'health')}
  let(:plan) { double("Plan") }
  let(:benefit_group){double("BenefitGroup")}
  let(:reference_plan){double("Plan")}
  let(:tax_household) {double}
  let(:household) {double(latest_active_tax_household_with_year: tax_household)}
  let(:family) {double(latest_household: household)}
  context "GET comparison" do
    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(plan).to receive(:coverage_kind).and_return("health")
      allow(benefit_group).to receive(:decorated_elected_plans).with(hbx_enrollment, plan.coverage_kind)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
    end

    it "should return comparison of multiple plans" do
      sign_in(user)
      get :comparison, standard_component_ids: ["11111111111111-01", "11111111111111-02"]
      expect(response).to have_http_status(:success)
    end
  end

  context "GET summary" do
    let(:hbx_enrollment){ double("HbxEnrollment", is_shop?: false, id: double("id"), enrollment_kind: 'open_enrollment', plan: plan, coverage_kind: 'health') }
    let(:benefit_group){ double("BenefitGroup") }
    let(:reference_plan){ double("Plan") }
    let(:dental_reference_plan){ double("Plan") }
    let(:qhp_cost_share_variance){ double("QhpCostShareVariance", plan: double("Plan"), :hios_plan_and_variant_id => "id") }
    let(:qhp_cost_share_variances) { [qhp_cost_share_variance] }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:build_plan_premium).and_return(true)
      allow(hbx_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return(qhp_cost_share_variances)
    end

    it "should return summary of a plan for shop and coverage_kind as health" do
      allow(hbx_enrollment).to receive(:plan).and_return(false)
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015", market_kind: "shop", coverage_kind: "health"
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "employer_sponsored"
      expect(assigns(:coverage_kind)).to eq "health"
    end

    it "should return summary of a plan for shop and coverage_kind as dental" do
      allow(plan).to receive(:coverage_kind).and_return("dental")
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015", market_kind: "shop", coverage_kind: "dental"
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "employer_sponsored"
      expect(assigns(:coverage_kind)).to eq "dental"
    end

    it "should return dental plan if hbx_enrollment does not have plan object" do
      allow(hbx_enrollment).to receive(:kind).and_return("individual")
      allow(plan).to receive(:coverage_kind).and_return("dental")
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      allow(hbx_enrollment).to receive(:plan).and_return(nil)
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015", market_kind: "individual", coverage_kind: "dental"
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "individual"
      expect(assigns(:coverage_kind)).to eq "dental"
    end

    it "should return summary of a plan for ivl and coverage_kind: health" do
      allow(hbx_enrollment).to receive(:kind).and_return("individual")
      allow(hbx_enrollment).to receive(:plan).and_return(false)
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015", market_kind: "individual", coverage_kind: "health"
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "individual"
      expect(assigns(:coverage_kind)).to eq "health"
      expect(assigns(:benefit_group)).to be_falsey
      expect(assigns(:reference_plan)).to be_falsey
    end

    it "should return summary of a plan for ivl and coverage_kind: dental" do
      allow(hbx_enrollment).to receive(:kind).and_return("individual")
      allow(plan).to receive(:coverage_kind).and_return("dental")
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: hbx_enrollment.id, active_year: "2015", market_kind: "individual", coverage_kind: "dental"
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "individual"
      expect(assigns(:coverage_kind)).to eq "dental"
      expect(assigns(:benefit_group)).to be_falsey
      expect(assigns(:reference_plan)).to be_falsey
    end
  end

  context "GET summary with bad HbxEnrollment" do

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(nil)
    end

    it "should fail when bad data" do
      sign_in(user)
      get :summary, standard_component_id: "11111100001111-01", hbx_enrollment_id: '999', active_year: "2015", market_kind: "shop", coverage_kind: "health"
      expect(response).to have_http_status(500)
    end
  end

  context "GET comparison when get more than one qhp" do
    let(:hbx_enrollment){ HbxEnrollment.new(coverage_kind: 'dental') }
    let(:benefit_group){ double("BenefitGroup") }
    let(:reference_plan){ double("Plan") }
    let(:qhp1) { Products::QhpCostShareVariance.new(hios_plan_and_variant_id: "11111100001111-01") }
    let(:qhp2) { Products::QhpCostShareVariance.new(hios_plan_and_variant_id: "11111100001111-02") }
    let(:plan1) { double("Plan", hios_id: "11111100001111-01") }
    let(:plan2) { double("Plan", hios_id: "11111100001111") }

    let(:qhp3) { Products::QhpCostShareVariance.new(hios_plan_and_variant_id: "11111100001111-03") }
    let(:qhp4) { Products::QhpCostShareVariance.new(hios_plan_and_variant_id: "11111100001111-04") }
    let(:plan3) { double("Plan", hios_id: "11111100001111-02") }
    let(:plan4) { double("Plan", hios_id: "11111100001112") }


    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:decorated_elected_plans).with("dental")
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return([qhp1, qhp2])
      allow(qhp1).to receive(:plan).and_return plan1
      allow(qhp2).to receive(:plan).and_return plan2
      allow(qhp3).to receive(:plan).and_return plan3
      allow(qhp4).to receive(:plan).and_return plan4
      allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_employee_cost: 100))
      allow(hbx_enrollment).to receive(:plan).and_return(plan)
      allow(plan).to receive(:coverage_kind).and_return("dental")
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.year)
    end

    it "should return comparison of a plan" do
      sign_in(user)
      get :comparison, standard_component_ids: ["11111100001111-01", "11111100001111-02"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'
      expect(response).to have_http_status(:success)
      expect(assigns(:qhps).count).to eq 2
    end

    context "should return uniq plans" do
      before :each do
        # allow(Products::QhpCostShareVariance).to receive(:find).and_return([qhp1, qhp2, qhp3, qhp4])
        sign_in(user)
      end

      it "should return uniq plans when same plan" do
        get :comparison, standard_component_ids: ["11111100001111-01", "11111100001111-01"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'
        expect(response).to be_success
        expect(assigns(:qhps).count).to eq 2
      end

      it "should return uniq plans when 2" do
        get :comparison, standard_component_ids: ["11111100001111-01", "11111100001111-02"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'
        expect(response).to be_success
        expect(assigns(:qhps).count).to eq 2
      end
    end
  end
end
