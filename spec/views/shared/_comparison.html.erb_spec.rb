require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe "shared/_comparison.html.erb", dbclean: :after_each do

  after :all do
    DatabaseCleaner.clean
  end

  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,
    enrollment_members: family.family_members,
    household: family.active_household,
    family: family,
    product_id: product.id,
    benefit_sponsorship_id: benefit_sponsorship.id,
    sponsored_benefit_package_id: current_benefit_package.id
  )}

  let(:primary_family_member) { family.family_members.first }

  let(:hbx_enrollment_member) { FactoryBot.create(:hbx_enrollment_member,
    applicant_id: primary_family_member.id,
    hbx_enrollment: hbx_enrollment,
    is_subscriber: primary_family_member.is_primary_applicant,
    coverage_start_on: hbx_enrollment.effective_on,
    eligibility_date: hbx_enrollment.effective_on
  )}

  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }

  let(:plan) { FactoryBot.create(:plan,
   provider_directory_url: "http://www.example1.com",
   rx_formulary_url: "http://www.example.com") } # QHP still checking for old plan instance for rx_formulary_url & provider_directory_url in view file.
  
  let(:mock_qhp){instance_double("Products::QhpCostShareVariance", :product => product, :plan => plan, :plan_marketing_name=> product.title)}
  let(:mock_qhps) {[mock_qhp]}
  let(:sbc_document) { double("SbcDocument", identifier: "download#abc") }
  let(:mock_family){ double("Family") }

  before :each do
    allow(mock_qhp).to receive("[]").with(:total_employee_cost).and_return(30)
    assign(:visit_types, [])
    assign :person, primary_family_member.person
    assign :member_groups, []
    assign :hbx_enrollment, hbx_enrollment_member.hbx_enrollment
  end

  context "with no rx_formulary_url and provider urls for coverage_kind = dental" do

    before :each do
      assign :coverage_kind, "dental"
      assign :market_kind, 'shop'
      render "shared/comparison", :qhps => mock_qhps
    end

    it "should not have coinsurance text" do
      expect(rendered).not_to have_selector('th', text: 'COINSURANCE')
    end

    it "should not have copay text" do
      expect(rendered).not_to have_selector('th', text: 'CO-PAY')
    end

    it "should not have download link" do
      expect(rendered).not_to have_selector('a', text: 'Download')
      expect(rendered).not_to have_selector('a[href="/products/plans/comparison.csv?coverage_kind=dental"]', text: "Download")
    end

  end

  context "with no rx_formulary_url and provider urls for coverage_kind = health" do

    before :each do
      assign :coverage_kind, "health"
      assign :market_kind, 'shop'
      allow(product).to receive(:sbc_document).and_return double("Document", :identifier => "identifier")
      render "shared/comparison", :qhps => mock_qhps
    end

    it "should have a link to open the sbc pdf" do
      expect(rendered).to have_selector('a', text: "Summary of Benefits and Coverage")
    end

    it "should contain some readable text" do
      ["$30.00", "#{product.title}", "#{product.product_type.upcase}"].each do |t|
        expect(rendered).to have_content(t)
      end
    end

    it "should have print area" do
      expect(rendered).to have_selector('div#printArea')
    end

    it "should not have plan details text" do
      expect(rendered).not_to match(/Plan Details/)
    end

    it "should have download link" do
      expect(rendered).to have_selector('a[href]', text: 'Download')
    end

    it "should not have Out of Network text" do
      expect(rendered).to_not have_selector('th', text: 'Out of Network')
    end

    it "should have cost sharing text" do
      expect(rendered).to have_selector('th', text: 'COST SHARING')
    end

    it "should not have copay text" do
      expect(rendered).to_not have_selector('th', text: 'CO-PAY')
    end

    it "should have title text" do
      expect(rendered).to match("Once you meet your deductible, you'll share the costs for any covered services you receive until you reach your out-of-pocket limit. Copayments are a fixed dollar amount you pay for a covered service, usually when you receive the service. Coinsurance is calculated as a percent of the allowed amount for a covered service.")
    end

    it "should have plan data" do
      expect(rendered).to match(/#{product.title}/)
    end

    it "should have print link" do
      expect(rendered).to have_selector('button', text: 'Print')
    end

    it "should have title and other text" do
      expect(rendered).to have_selector('h1', text: /Choose Plan - Compare Selected Plans/ )
      expect(rendered).to have_selector('h4', text: /Each plan is different. Make sure you understand the differences so you can find the right plan to meet your needs and budget./ )
    end
  end

  context "provider_directory_url and rx_formulary_url" do
    # View file is checking for both Plan & Product instances. Does this needs to be fixed?
    before do
      assign :plans, [hbx_enrollment.product]
      allow(product).to receive(:rx_formulary_url).and_return plan.rx_formulary_url
      assign :market_kind, 'shop'
    end

    it "should have rx formulary url coverage_kind = health" do
      plan.update_attributes!(nationwide: true)
      render "shared/comparison", :qhps => mock_qhps
      expect(rendered).to match(/#{plan.rx_formulary_url}/)
      expect(rendered).to match("DOCTOR DIRECTORY")
    end

    if aca_state_abbreviation == "DC" # There is no plan comparision for MA dental
      context 'for dental coverage' do
        let!(:dental_product) { FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile) }
        let!(:dental_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', hios_id: "91111111122302", coverage_kind: 'dental', dental_level: 'high') }
        let!(:mock_qhp){instance_double("Products::QhpCostShareVariance", :product => dental_product, :plan => dental_plan, :plan_marketing_name => dental_product.title)}
        let(:mock_qhps) {[mock_qhp]}
        it "should not have rx_formulary_url coverage_kind = dental" do
          render "shared/comparison", :qhps => mock_qhps
          expect(rendered).to_not have_selector('a', text: 'DRUG LIST')
        end
      end
    end

    if offers_nationwide_plans?
      it "should have provider directory url if nationwide = true" do
        plan.update_attributes!(nationwide: true)
        render "shared/comparison", :qhps => mock_qhps
        expect(rendered).to match(/#{plan.provider_directory_url}/)
      end

      it "should not have provider directory url if nationwide = false" do
        allow(view).to receive(:offers_nationwide_plans?).and_return(true)
        allow(plan).to receive(:nationwide).and_return(false)
        allow(plan).to receive(:service_area_id).and_return('XX-111')
        render "shared/comparison", :qhps => mock_qhps
        expect(rendered).to_not match(/#{plan.provider_directory_url}/)
      end
    end
  end
end
