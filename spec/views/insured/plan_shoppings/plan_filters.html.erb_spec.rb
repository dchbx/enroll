require "rails_helper"

RSpec.describe "insured/_plan_filters.html.erb" do
  let(:benefit_group){ double("BenefitGroup") }
  let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment) }
  context "without consumer_role" do
    let(:person) {double(has_active_consumer_role?: false)}
    before :each do
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:benefit_group, benefit_group)
      assign(:max_total_employee_cost, 1000)
      assign(:max_deductible, 998)
      assign(:hbx_enrollment, hbx_enrollment)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_carrier")
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it 'should display find your doctor link' do
      expect(rendered).to have_selector('a', text: /estimate your costs/i)
    end

    it 'should display filter selections' do
      expect(rendered).to match /HSA Eligibility/i
      expect(rendered).to match /Carrier/
      expect(rendered).to have_selector('select', count: 2)
    end

    it "should have Premium amount search" do
      expect(rendered).to match /Premium Amount/
      expect(rendered).to have_selector("input[value='1000']", count: 2)
    end

    it "should have Deductible Amount search" do
      expect(rendered).to match /Deductible Amount/
      expect(rendered).to have_selector("input[value='998']", count: 2)
    end
  end

  context "with employee role in employee flow" do
    let(:person){ double("Person") }
    let(:metal_levels){ Plan::METAL_LEVEL_KINDS[0..4] }
    before(:each) do
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:benefit_group, benefit_group)
      allow(person).to receive(:has_active_consumer_role?).and_return(false)
      allow(person).to receive(:has_active_employee_role?).and_return(true)
      assign(:hbx_enrollment, hbx_enrollment)

    end

    it 'should display find your doctor link' do
      expect(rendered).to_not have_selector('a', text: /estimate your costs/i)
    end

    it "should display metal level filters if plan_option_kind is single_carrier" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_carrier")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
      metal_levels.each do |metal_level|
        expect(rendered).to have_selector("input[id='plan-metal-level-#{metal_level}']")
      end
      expect(rendered).to match(/Metal Level/m)
    end

    it "should not display metal level filters if plan_option_kind is single_plan" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
      metal_levels.each do |metal_level|
        expect(rendered).not_to have_selector("input[id='plan-metal-level-#{metal_level}']")
      end
      expect(rendered).not_to match(/Metal Level/m)
    end

    it "should not display metal level filters if plan_option_kind is metal_level" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("metal_level")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
      metal_levels.each do |metal_level|
        expect(rendered).not_to have_selector("input[id='plan-metal-level-#{metal_level}']")
      end
      expect(rendered).not_to match(/Metal Level/m)
    end

  end

  context "with consumer_role and tax_household" do
    let(:person) {double(has_active_consumer_role?: true)}


    before :each do
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:max_total_employee_cost, 1000)
      assign(:max_deductible, 998)
      assign(:max_aptc, 330)
      assign(:market_kind, 'individual')
      assign(:tax_household, true)
      assign(:benefit_group, benefit_group)
      assign(:selected_aptc_pct, 0.85)
      assign(:elected_aptc, 280.50)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_carrier")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it "should have aptc area" do
      expect(rendered).to have_selector('div.aptc')
      expect(rendered).to have_selector('input#max_aptc')
      expect(rendered).to have_selector('input#set_elected_aptc_url')
      expect(rendered).to have_selector("input[name='elected_pct']")
    end

    it "should have Aptc used" do
      expect(rendered).to match /Used/
      expect(rendered).to have_selector("input#elected_aptc")
    end

    it "should have aptc available" do
      expect(rendered).to match /APTC/
      expect(rendered).to match /Available/
      expect(rendered).to match /330/
    end

    it "should have selected aptc pct amount" do
      expect(rendered).to match /85/
      expect(rendered).to have_selector("input#elected_aptc[value='280.50']")
    end
  end

  context "with tax_household plan_shopping in shop market" do
    let(:person) {double(has_active_consumer_role?: true)}

    before :each do
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:max_total_employee_cost, 1000)
      assign(:max_deductible, 998)
      assign(:max_aptc, 330)
      assign(:market_kind, 'shop')
      assign(:tax_household, true)
      assign(:benefit_group, benefit_group)
      assign(:selected_aptc_pct, 0.85)
      assign(:elected_aptc, 280.50)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_carrier")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it "should not have aptc area in shop market" do
      expect(rendered).not_to have_selector('div.aptc')
      expect(rendered).not_to have_selector('input#max_aptc')
      expect(rendered).not_to have_selector('input#set_elected_pct_url')
      expect(rendered).not_to have_selector("input[name='elected_pct']")
    end
  end

  context "with consumer_role but without tax_household" do
    let(:person) {double(has_active_consumer_role?: true)}

    before :each do
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:person, person)
      assign(:carriers, Array.new)
      assign(:market_kind, 'shop')
      assign(:max_total_employee_cost, 1000)
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:benefit_group, benefit_group)
      assign(:tax_household, nil)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_carrier")
      render :template => "insured/plan_shoppings/_plan_filters.html.erb"
    end

    it "should not have aptc area" do
      expect(rendered).not_to have_selector('div.aptc')
      expect(rendered).not_to have_selector('input#max_aptc')
      expect(rendered).not_to have_selector('input#set_elected_pct_url')
      expect(rendered).not_to have_selector("input[name='elected_pct']")
    end
  end
end
