require "rails_helper"

RSpec.describe "insured/_plan_filters.html.erb" do
  let(:benefit_group){ double("BenefitGroup") }
  let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment) }
  context "without consumer_role" do
    let(:person) {double(is_consumer_role_active?: false)}
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
      expect(rendered).to have_selector("a[href='https://dc.checkbookhealth.org/hie/dc/#{hbx_enrollment.plan.active_year}/']")
    end

    it 'should display filter selections' do
      expect(rendered).to match /HSA Eligible/i
      expect(rendered).to match /Carrier/
      expect(rendered).to have_selector('select', count: 2)
    end

    it 'should have Metal Level title text' do
      expect(rendered).to match /Plans use metal levels as an easy way to help indicate how generous they are in paying expenses.
    Metal levels only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or service providers available through the health insurance plan./i
    end

    it 'should have Bronze title text' do
      expect(rendered).to match /Bronze means the plan is expected to pay 60% of medical expenses for the average population of consumers. Bronze plans generally have low premiums, but you pay more when you get covered services./i
    end

    it 'should have Silver title text' do
      expect(rendered).to match /Silver means the plan is expected to pay 70% of medical expenses for the average population of consumers. Silver plans generally have lower premiums, but you pay more when you get covered services./i
    end

    it 'should have Gold title text' do
      expect(rendered).to match /Gold means the plan is expected to pay 80% of medical expenses for the average population of consumers. Gold plans typically have higher premiums, but you pay less when you get covered services./i
    end

    it 'should have Platinum title text' do
      expect(rendered).to match /Platinum means the plan is expected to pay 90% of medical expenses for the average population of consumers. Platinum plans typically have high premiums, but you pay less when you get covered services./i
    end

    it 'should have Catastrophic title text' do
      expect(rendered).to match /While not a metal level plan, catastrophic plans are another group of plans that have low monthly premiums and high annual deductibles. The plans are designed to protect consumers from worst case situations like a serious illness or an accident. Catastrophic plans are only available to people under 30 or people with a hardship exemption./i
    end

    it 'should have Plan Type title text ' do
      expect(rendered).to match /The plan type you choose impacts which doctors you can see, whether or not you can use out-of-network providers, and how much you‘ll pay./i
    end

    it 'should have Network title text' do
      expect(rendered).to match /Doctors, specialists, other providers, facilities and suppliers that a health insurance company contracts with to provide health care services to plan members./i
    end

    it 'should have Nationwide title text' do
      expect(rendered).to match /The plan has a national network of doctors, specialists, other providers, facilities and suppliers that plan members can access./i
    end

    it 'should have DC-Metro title text' do
      expect(rendered).to match /The plan has a local network of doctors, specialists, other providers, facilities and suppliers that plan members can access./i
    end

    it 'should have HMO title text' do
      expect(rendered).to match /#{Regexp.escape("An HMO (Health Maintenance Organization) plan usually only covers care from in-network providers. It generally won‘t cover out-of-network care except in an emergency, and may require you to live or work in its service area to be eligible for coverage. You may be required to choose a primary care doctor.")}/i
    end

    it 'should have PPO title text' do
      expect(rendered).to match /#{Regexp.escape("A PPO (Preferred Provider Organization) plan covers care from in-network and out-of-network providers. You pay less if you use providers that belong to the plan’s network. You can use providers outside of the network for an additional cost.")}/i
    end

    it 'should have POS title text' do
      expect(rendered).to match /#{Regexp.escape("A POS (Point-of-Service) plan is a combination of an HMO and a PPO. Typically it has a network that functions like an HMO – you pick a primary care doctor, who manages and coordinates your care within the network. Similar to a PPO, POS plans usually also allow you to use a provider who is not in the network.")}/i
    end

    it 'should have Hsa_eligibilty title text' do
      expect(rendered).to match(/#{Regexp.escape("Plans that are eligible for HSA (Health Savings Accounts) are classified as High Deductible Health Plans (HDHP) and enable you to open a tax-preferred medical savings account at your bank to pay for qualified medical expenses. Funds in an HSA account roll over year to year if you don‘t spend them.")}/i)
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
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
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
    let(:person) {double(is_consumer_role_active?: true)}


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
    let(:person) {double(is_consumer_role_active?: true)}

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
    let(:person) {double(is_consumer_role_active?: true)}

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
