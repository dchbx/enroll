require 'rails_helper'

RSpec.describe "_summary.html.slim.rb", :type => :view, dbclean: :after_each  do
  let(:aws_env) { ENV['AWS_ENV'] || "qa" }
  let(:person) {FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:active_household) {family.active_household}
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, applicant_id: family.family_members.first.id, coverage_start_on: TimeKeeper.date_of_record, eligibility_date: TimeKeeper.date_of_record) }
  let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,household: active_household, family: family, hbx_enrollment_members:[hbx_enrollment_member])}
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id, product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: mock_product, member_enrollments:[member_enrollment])}
  let(:member_group) {double(group_enrollment:group_enrollment)}

  let(:mock_issuer_profile) { double("IssuerProfile", :dba => "a carrier name", :legal_name => "name") }

  let(:mock_product) { double("Product",
      :active_year => 2018,
      :title => "A Plan Name",
      :carrier_profile_id => "a carrier profile id",
      :issuer_profile => mock_issuer_profile,
      :metal_level_kind => "Silver",
      :product_type => "A plan type",
      :nationwide => true,
      :network_information => "This is a test",
      :deductible => 0,
      :total_premium => 0,
      :total_employer_contribution => 0,
      :total_employee_cost => 0,
      :rx_formulary_url => "http://www.example.com",
      :provider_directory_url => "http://www.example1.com",
      :ehb => 0.988,
      :hios_id => "89789DC0010006-01",
      :id => "1234234234",
      :kind => :health,
      :health_plan_kind => "HMO",
      :sbc_file => "THE SBC FILE.PDF",
      :is_standard_plan => true,
      :can_use_aptc? => true,
      :sbc_document => Document.new({title: 'sbc_file_name', subject: "SBC",
                                     :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}#7816ce0f-a138-42d5-89c5-25c5a3408b82"})
      ) }
  let(:mock_qhp_cost_share_variance) { instance_double(Products::QhpCostShareVariance, :qhp_service_visits => []) }

  before :each do
    Caches::MongoidCache.release(CarrierProfile)
    allow(person).to receive(:primary_family).and_return(family)
    allow(family).to receive(:enrolled_hbx_enrollments).and_return([hbx_enrollment])
    assign :person, person
    assign :plan, mock_product
    assign :hbx_enrollment, hbx_enrollment
    assign :member_group, member_group
  end

  it "should display standard plan indicator" do
    render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
    expect(rendered).to have_selector('i', text: 'STANDARD PLAN')
  end

  context "with no rx_formulary_url and provider urls for coverage_kind = dental" do
    before :each do
      assign :coverage_kind, "dental"
      allow(mock_product).to receive(:kind).and_return("dental")
      allow(mock_product).to receive(:dental_level).and_return("high")
      allow(mock_product).to receive(:rx_formulary_url).and_return nil
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
    end

    it "should not have coinsurance text" do
      expect(rendered).to have_selector('th', text: 'COINSURANCE')
    end

    it "should not have copay text" do
      expect(rendered).to have_selector('th', text: 'CO-PAY')
    end
  end

  context "with no provider_directory_url and rx_formulary_urls with coverage_kind = health" do

    before :each do
      assign(:coverage_kind, "health")
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
    end

    it "should have a link to download the sbc pdf" do
      expect(rendered).to have_selector("a[href='#{"/document/download/#{Settings.site.s3_prefix}-enroll-sbc-qa/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
    end

    it "should have a label 'Summary of Benefits and Coverage (SBC)'" do
      expect(rendered).to include('Summary of Benefits and Coverage')
    end

    it "should not have 'having a baby'" do
      expect(rendered).not_to have_selector("h4", text: "Having a Baby")
    end

    it "should not have 'managing type diabetes'" do
      expect(rendered).not_to have_selector("h4", text: "Managing Type 2 Diabetes")
    end
  end

  context "provider_directory_url and rx_formulary_url" do

    it "should have rx formulary url coverage_kind = health" do
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
      expect(rendered).to match(/#{mock_product.rx_formulary_url}/)
    end

    it "should not have rx_formulary_url coverage_kind = dental" do
      allow(mock_product).to receive(:kind).and_return("dental")
      allow(mock_product).to receive(:dental_level).and_return("high")
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
      expect(rendered).to_not match(/#{mock_product.rx_formulary_url}/)
    end

    it "should have provider directory url if nationwide = true" do
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
      expect(rendered).to match(/#{mock_product.provider_directory_url}/)
      expect(rendered).to match("PROVIDER DIRECTORY")
    end

    it "should not have provider directory url if nationwide = false(for dc)" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(true)
      allow(mock_product).to receive(:nationwide).and_return(false)
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
      expect(rendered).to_not match(/#{mock_product.provider_directory_url}/)
    end

    it "should not have provider directory url if nationwide = false(for ma)" do
      allow(view).to receive(:offers_nationwide_plans?).and_return(false)
      allow(mock_product).to receive(:nationwide).and_return(false)
      render "ui-components/v1/cards/summary", :qhp => mock_qhp_cost_share_variance
      expect(rendered).to match(/#{mock_product.provider_directory_url}/)
    end
  end
end
