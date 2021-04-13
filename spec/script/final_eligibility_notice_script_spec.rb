# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe "FinalEligibilityNoticeScript", :dbclean => :after_each do
  include_context 'setup benefit market with market catalogs and product packages'

  let!(:person3) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141892", first_name: "John", last_name: "Smith") }
  let!(:person4) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141891", first_name: "John", last_name: "Smith1") }
  let!(:family_member4) { FactoryBot.create(:family_member, family: family3, person: person4) }
  let(:consumer_role) { person3.consumer_role }

  let!(:family3) { FactoryBot.create(:family, :with_primary_family_member, person: person3) }

  let(:dependents) { family3.family_members }

  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }

  let(:application_period) { effective_on..effective_on.end_of_year }

  let(:hbx_en_member3) do
    FactoryBot.build(
      :hbx_enrollment_member,
      eligibility_date: effective_on,
      coverage_start_on: effective_on,
      applicant_id: dependents[0].id
    )
  end

  let(:hbx_en_member4) do
    FactoryBot.build(
      :hbx_enrollment_member,
      eligibility_date: effective_on,
      coverage_start_on: effective_on,
      applicant_id: dependents[1].id
    )
  end

  let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }

  let(:product) do
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      :with_renewal_product,
      :with_issuer_profile,
      benefit_market_kind: :aca_individual,
      kind: :health,
      assigned_site: site,
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      csr_variant_id: '01',
      application_period: application_period
    )
  end

  let(:renewal_product) { product.renewal_product }

  let!(:current_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      family: family3,
      product: product,
      household: family3.active_household,
      coverage_kind: "health",
      effective_on: effective_on,
      kind: 'individual',
      hbx_enrollment_members: [hbx_en_member3, hbx_en_member4],
      aasm_state: 'coverage_selected'
    )
  end

  let!(:renewing_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      family: family3,
      product: renewal_product,
      household: family3.active_household,
      coverage_kind: "health",
      effective_on: effective_on.next_year,
      kind: 'individual',
      hbx_enrollment_members: [hbx_en_member3, hbx_en_member4],
      aasm_state: 'auto_renewing'
    )
  end

  let(:input_file) { Rails.root.join("spec", "test_data", "notices", "ivl_fel_aqhp_test_data.csv") }

  let(:error_message) {"Please include mandatory arguments: File name and Event name. Example: rails runner script/final_eligibility_notice_script.rb <file_name> <event_name> <eligibility_kind> <file_path_to_exclude>"}

  it "should raise error when arguments are not passed" do
    expect{ invoke_script(false) }.to raise_error(RuntimeError, error_message)
  end

  it "should create report" do
    invoke_script
    data = export_file_reader
    expect(data[0].present?).to eq true
    expect(data[1].present?).to eq true
    expect(data[1][0]).to eq('2141809')
    expect(data[1][1]).to eq(person3.hbx_id.to_s)
    expect(data[1][2]).to eq(person3.first_name)
    expect(data[1][3]).to eq(person3.last_name)
  end

  after :all do
    FileUtils.rm_rf(Dir.glob(File.join(Rails.root, 'spec/test_data/notices/final_eligibility_notice_aqhp_report_*.csv')))
  end
end

private

def export_file_reader
  files = Dir.glob(File.join(Rails.root, 'spec/test_data/notices/final_eligibility_notice_aqhp_report_*.csv'))
  CSV.read files.first
end

def invoke_script(with_params = true)
  if with_params
    ARGV[0] = input_file
    ARGV[1] = 'final_eligibility_notice'
    ARGV[2] = 'aqhp'
    ARGV[3] = 'spec/test_data/notices/ivl_fel_aqhp_test_data.csv'
  else
    ARGV[0] = nil
    ARGV[1] = nil
    ARGV[2] = nil
  end
  final_eligibility_notice = File.join(Rails.root, "script/final_eligibility_notice_script.rb")
  load final_eligibility_notice
end