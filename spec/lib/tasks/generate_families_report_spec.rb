require 'rails_helper'
require 'rake'

RSpec.describe 'generate_families_report' do
  let!(:eligibility_date) {TimeKeeper.datetime_of_record}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
  let!(:tax_household) {FactoryGirl.create(:tax_household, household: family.active_household, effective_starting_on: Date.new(2018, 1, 1), effective_ending_on: Date.new(2019, 1, 1))}
  let!(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household, max_aptc: {"cents" => 283.00, "currency_iso" => "USD"})}
  let!(:tax_household2) {FactoryGirl.create(:tax_household, household: family.active_household, effective_starting_on: Date.new(2019, 1, 1), effective_ending_on: nil)}
  let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household2, max_aptc: {"cents" => 50.00, "currency_iso" => "USD"})}

  let!(:family2) {FactoryGirl.create(:family, :with_primary_family_member)}
  let!(:tax_household3) {FactoryGirl.create(:tax_household, household: family2.active_household, effective_starting_on: Date.new(2018, 1, 1), effective_ending_on: nil)}
  let!(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household3, max_aptc: {"cents" => 1.00, "currency_iso" => "USD"})}

  let!(:family3) {FactoryGirl.create(:family, :with_primary_family_member)}
  let!(:tax_household4) {FactoryGirl.create(:tax_household, household: family3.active_household, effective_starting_on: Date.new(2018, 1, 1), effective_ending_on: Date.new(2017, 1, 31))}
  let!(:eligibility_determination4) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household4, max_aptc: {"cents" => 3.00, "currency_iso" => "USD"})}

  let!(:family4) {FactoryGirl.create(:family, :with_primary_family_member)}
  let!(:tax_household5) {FactoryGirl.create(:tax_household, household: family4.active_household, effective_starting_on: Date.new(2018, 1, 1), effective_ending_on: Date.new(2018, 12, 31))}
  let!(:eligibility_determination5) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household5, max_aptc: {"cents" => 283.00, "currency_iso" => "USD"})}
  let!(:tax_household6) {FactoryGirl.create(:tax_household, household: family4.active_household, effective_starting_on: Date.new(2019, 1, 1), effective_ending_on: nil)}
  let!(:eligibility_determination6) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household6, max_aptc: {"cents" => 50.00, "currency_iso" => "USD"})}


  before do
    load File.expand_path("#{Rails.root}/lib/tasks/generate_families_report.rake", __FILE__)
    Rake::Task.define_task(:environment)
    ENV['tax_household_year'] = "2018"
    Rake::Task["generate_report:families"].invoke()
  end

  context "should generate report" do
    it 'with one family having inactive THH with current year and active THH with next year ' do
      result = ['hbx_id', 'first_name', 'last_name', 'ssn', '2018_max_aptc', '2018_csr', '2018_thh_effective_start_date', '2018_thh_effective_end_date', '2018_e_pdc_id', '2018_created_source', '2019_thh_effective_start_date', '2019_thh_effective_end_date', '2019_e_pdc_id', '2019_created_source']
      files = Dir.glob(File.join(Rails.root, "hbx_report", "families_with_inactive_tax_household_*.csv"))
      data = CSV.read files.first
      expect(data[0]).to eq result
      expect(data[1].present?).to eq true
      expect(data.count).to eq 2
    end

    after(:all) do
      dir_path = "#{Rails.root}/hbx_report/"
      Dir.foreach(dir_path) do |file|
        File.delete File.join(dir_path, file) if File.file?(File.join(dir_path, file))
      end
      Dir.delete(dir_path)
    end
  end
end
