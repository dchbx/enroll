require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Products::QhpController, :type => :controller, dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:household){ family.active_household }
  let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                           family: household.family,
                                           household: household,
                                           hbx_enrollment_members: [hbx_enrollment_member],
                                           coverage_kind: "health",
                                           external_enrollment: false,
                                           sponsored_benefit_id: sponsored_benefit.id,
                                           rating_area_id: rating_area.id)}
  let(:benefit_group) { current_benefit_package }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:dental_sponsored_benefit) { true }
  let(:product_kinds) { [:health, :dental] }
  let(:package_kind) { :single_product }
  let(:package) { initial_application.benefit_packages[0] }
  let(:shop_health_enrollment) { FactoryBot.create(:hbx_enrollment,
    family: family,
    household: family.active_household,
    product: health_products[0],
    sponsored_benefit_id: package.health_sponsored_benefit.id,
    benefit_sponsorship_id: benefit_sponsorship.id,
    sponsored_benefit_package_id: package.id,
    rating_area_id: rating_area.id
  )}

  let(:shop_dental_enrollment) { FactoryBot.create(:hbx_enrollment,
    family: family,
    household: family.active_household,
    product: dental_products[0],
    sponsored_benefit_id: package.dental_sponsored_benefit.id,
    benefit_sponsorship_id: benefit_sponsorship.id,
    sponsored_benefit_package_id: package.id,
    rating_area_id: rating_area.id
  )}

  let(:ivl_health_enrollment) { FactoryBot.create(:hbx_enrollment,
    household: family.active_household,
    coverage_kind: "health"
  )}

  let(:ivl_dental_enrollment) { FactoryBot.create(:hbx_enrollment,
    household: family.active_household,
    coverage_kind: "dental"
  )}

  context "GET comparison", :dbclean => :around_each do

    it "should return comparison of multiple plans" do
      sign_in(user)      
      get :comparison, params: {standard_component_ids: ["11111111111111-01", "11111111111111-02"], hbx_enrollment_id: shop_health_enrollment.id, active_year: shop_health_enrollment.effective_on.year, market_kind: "shop", coverage_kind: "health"}      
      expect(response).to have_http_status(:success)
    end
  end

  context "GET summary", :dbclean => :around_each do

    let(:qhp_cost_share_variance){ double("QhpCostShareVariance", product: double("Product"), :hios_plan_and_variant_id => "id") }
    let(:qhp_cost_share_variances) { [qhp_cost_share_variance] }

    before do
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return(qhp_cost_share_variances)
    end

    it "should return summary of a plan for shop and coverage_kind as health" do
      sign_in(user)
      get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_health_enrollment.id, active_year: shop_health_enrollment.effective_on.year, market_kind: "shop", coverage_kind: "health"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "employer_sponsored"
      expect(assigns(:coverage_kind)).to eq "health"
    end

    it "should return summary of a plan for shop and coverage_kind as dental" do
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      sign_in(user)
      get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_dental_enrollment.id, active_year: shop_dental_enrollment.effective_on.year, market_kind: "shop", coverage_kind: "dental"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "employer_sponsored"
      expect(assigns(:coverage_kind)).to eq "dental"
    end

    # if individual_market_is_enabled?
    #   it "should return dental plan if hbx_enrollment does not have plan object" do
    #     allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
    #     sign_in(user)
    #     get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: ivl_health_enrollment.id, active_year: ivl_health_enrollment.effective_on.year, market_kind: "individual", coverage_kind: "dental"}
    #     expect(response).to have_http_status(:success)
    #     expect(assigns(:market_kind)).to eq "individual"
    #     expect(assigns(:coverage_kind)).to eq "dental"
    #   end
    #
    #   it "should return summary of a plan for ivl and coverage_kind: health" do
    #     sign_in(user)
    #     get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: ivl_health_enrollment.id, active_year: ivl_health_enrollment.effective_on.year, market_kind: "individual", coverage_kind: "health"}
    #     expect(response).to have_http_status(:success)
    #     expect(assigns(:market_kind)).to eq "individual"
    #     expect(assigns(:coverage_kind)).to eq "health"
    #     expect(assigns(:benefit_group)).to be_truthy
    #     expect(assigns(:reference_plan)).to be_falsey
    #   end
    #
    #   it "should return summary of a plan for ivl and coverage_kind: dental" do
    #     allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
    #     sign_in(user)
    #     get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: ivl_health_enrollment.id, active_year: ivl_health_enrollment.effective_on.year, market_kind: "individual", coverage_kind: "dental"}
    #     expect(response).to have_http_status(:success)
    #     expect(assigns(:market_kind)).to eq "individual"
    #     expect(assigns(:coverage_kind)).to eq "dental"
    #     expect(assigns(:benefit_group)).to be_truthy
    #     expect(assigns(:reference_plan)).to be_falsey
    #   end
    # end
  end

  context "GET summary with bad HbxEnrollment", :dbclean => :around_each do

    before do
      allow(HbxEnrollment).to receive(:find).and_return(nil)
    end

    it "should fail when bad data" do
      sign_in(user)
      get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: '999', active_year: "2015", market_kind: "shop", coverage_kind: "health"}
      expect(response).to have_http_status(500)
    end
  end

  context "GET comparison when get more than one qhp", :dbclean => :around_each do
    let(:hbx_enrollment){ HbxEnrollment.new(coverage_kind: 'dental') }
    let(:reference_plan){ double("Product") }
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
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:decorated_elected_plans).with("dental")
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return([qhp1, qhp2])
      allow(qhp1).to receive(:product).and_return plan1
      allow(qhp2).to receive(:product).and_return plan2
      allow(qhp3).to receive(:product).and_return plan3
      allow(qhp4).to receive(:product).and_return plan4
      allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_employee_cost: 100))
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(product).to receive(:kind).and_return("dental")
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.year)
    end

    # if individual_market_is_enabled?
    #   it "should return comparison of a plan" do
    #     sign_in(user)
    #     get :comparison, params: {standard_component_ids: ["11111100001111-01", "11111100001111-02"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'}
    #     expect(response).to have_http_status(:success)
    #     expect(assigns(:qhps).count).to eq 2
    #   end
    #
    #   context "should return uniq plans" do
    #     before :each do
    #       allow(Products::QhpCostShareVariance).to receive(:find).and_return([qhp1, qhp2, qhp3, qhp4])
    #       sign_in(user)
    #     end
    #
    #     it "should return uniq plans when same plan" do
    #       get :comparison, params: {standard_component_ids: ["11111100001111-01", "11111100001111-01"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'}
    #       expect(response).to be_success
    #       expect(assigns(:qhps).count).to eq 2
    #     end
    #
    #     it "should return uniq plans when 2" do
    #       get :comparison, params: {standard_component_ids: ["11111100001111-01", "11111100001111-02"], hbx_enrollment_id: hbx_enrollment.id, market_kind: 'individual'}
    #       expect(response).to be_success
    #       expect(assigns(:qhps).count).to eq 2
    #     end
    #   end
    # end
  end
end
