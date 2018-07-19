require "rails_helper"

describe ::Importers::Mhc::ConversionEmployerPlanYearCreate, dbclean: :after_each do

  let!(:record_attrs) {
    {
      :action=>"Add",
      :fein=>"089403883",
      :enrolled_employee_count=>"2",
      :new_coverage_policy=>"First of the month following 30 days",
      :coverage_start=>"01/01/2017",
      :carrier=>"neighborhood health plan",
      :plan_selection=>"Sole Source",
      :single_plan_hios_id=>"41304MA0041055-01",
      :employee_only_rt_contribution=>"50",
      :employee_only_rt_premium=>"596.3",
      :employee_and_spouse_rt_offered=>"false",
      :employee_and_spouse_rt_contribution=>"50",
      :employee_and_spouse_rt_premium=>"1192.61",
      :employee_and_one_or_more_dependents_rt_offered=>"false",
      :employee_and_one_or_more_dependents_rt_contribution=>"50",
      :employee_and_one_or_more_dependents_rt_premium=>"1103.16",
      :family_rt_offered=>"false",
      :family_rt_contribution=>"50",
      :family_rt_premium=>"1699.46"
    }
  }

  let!(:registered_on) { TimeKeeper.date_of_record.beginning_of_month }
  let!(:default_plan_year_start) { (registered_on + 3.months).prev_year }

  let!(:fein) { record_attrs[:fein] }

  let!(:carrier_profile) {FactoryGirl.create(:carrier_profile, with_service_areas: 0, issuer_hios_ids: ['11111'], abbrev: 'NHP', offers_sole_source: true)}
  let!(:carrier_one_service_area) { create(:carrier_service_area, service_area_zipcode: '01862', issuer_hios_id: carrier_profile.issuer_hios_ids.first, active_year: default_plan_year_start.year) }
  let!(:plan) { FactoryGirl.create(:plan, carrier_profile: carrier_profile, active_year: default_plan_year_start.year, service_area_id: carrier_one_service_area.service_area_id, hios_id: record_attrs[:single_plan_hios_id]) }

  subject { Importers::Mhc::ConversionEmployerPlanYearCreate.new(record_attrs.merge({:default_plan_year_start => default_plan_year_start})) }

  let(:out_stream) { StringIO.new }
  let(:file_name) { File.join(Rails.root, "spec", "test_data", "conversion_employers", "Employer Full Launch Template_TEST_20171020.xlsx") }

  before :each do
    allow(CarrierServiceArea).to receive(:service_areas_for).and_return([carrier_one_service_area])
    importer = Importers::Mhc::ConversionEmployerSet.new(file_name, out_stream, registered_on.strftime('%Y-%m-%d'))
    importer.import!
    out_stream.rewind
  end

  pending "provided with employer date" do
    before do
      @employer = EmployerProfile.find_by_fein(fein)
    end

    it "should create plan year" do
      expect(@employer.present?).to be_truthy
      expect(@employer.plan_years.empty?).to be_truthy

      subject.save
      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first

      expect(plan_year.present?).to be_truthy
      expect(plan_year.start_on).to eq default_plan_year_start
    end

    it "should create benefit group with sole source plan offerings" do
      subject.save
      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first
      benefit_group = plan_year.benefit_groups.first

      expect(benefit_group.reference_plan).to eq plan
      expect(benefit_group.elected_plan_ids).to eq [plan.id]
      expect(benefit_group.plan_option_kind).to eq 'sole_source'
    end

    it "should create composite tiers" do
      subject.save

      employer_profile = @employer.reload
      plan_year = employer_profile.plan_years.first
      benefit_group = plan_year.benefit_groups.first

      composite_tiers = benefit_group.composite_tier_contributions

      employee_tier = composite_tiers.where(composite_rating_tier: "employee_only").first
      expect(employee_tier.offered).to be_truthy
      expect(employee_tier.employer_contribution_percent).to eq record_attrs[:employee_only_rt_contribution].to_f
      expect(employee_tier.final_tier_premium).to eq record_attrs[:employee_only_rt_premium].to_f

      employee_and_spouse_tier = composite_tiers.where(composite_rating_tier: "employee_and_spouse").first
      expect(employee_and_spouse_tier.offered).to be_falsey
      expect(employee_and_spouse_tier.employer_contribution_percent).to eq record_attrs[:employee_and_spouse_rt_contribution].to_f
      expect(employee_and_spouse_tier.final_tier_premium).to eq record_attrs[:employee_and_spouse_rt_premium].to_f

      employee_and_one_or_more_dependents_tier = composite_tiers.where(composite_rating_tier: "employee_and_one_or_more_dependents").first
      expect(employee_and_one_or_more_dependents_tier.offered).to be_falsey
      expect(employee_and_one_or_more_dependents_tier.employer_contribution_percent).to eq record_attrs[:employee_and_one_or_more_dependents_rt_contribution].to_f
      expect(employee_and_one_or_more_dependents_tier.final_tier_premium).to eq record_attrs[:employee_and_one_or_more_dependents_rt_premium].to_f

      family_tier = composite_tiers.where(composite_rating_tier: "family").first
      expect(family_tier.offered).to be_falsey
      expect(family_tier.employer_contribution_percent).to eq record_attrs[:family_rt_contribution].to_f
      expect(family_tier.final_tier_premium).to eq record_attrs[:family_rt_premium].to_f
    end
  end
end
