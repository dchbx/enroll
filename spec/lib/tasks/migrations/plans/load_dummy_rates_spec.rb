require 'spec_helper'

# TODO: Fix all of these specs.  They are far too fragile.
class DummyPlanRatesLoaderSpecHelper
  def self.invoke_dummy_rates_tasks
    Rake::Task["dump_dummy:premium_rates"].reenable
    Rake::Task["dump_dummy:premium_rates"].invoke
  end
end

# FIXME: It appears this task does not work correctly across years -
#       is this a bug?
describe "load_dummy_rates", dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean

    @start_date = Date.new(TimeKeeper.date_of_record.year, 7, 1)
    @end_date = Date.new(TimeKeeper.date_of_record.year, 9, 30)
    @application_period = Time.utc(@start_date.year, @start_date.month, @start_date.day)..Time.utc(@end_date.year, @end_date.month, @end_date.day)

    Rake.application.rake_require 'tasks/migrations/plans/load_dummy_rates'
    Rake::Task.define_task(:environment)
  end

  before :each do
    glob_pattern = File.join(Rails.root, "db/seedfiles/cca/issuer_profiles_seed.rb")
    load glob_pattern
    load_cca_issuer_profiles_seed

    issuer_profiles = BenefitSponsors::Organizations::Organization.issuer_profiles.all
    @hp1 = FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[0].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))
    @hp2 = FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[1].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))
    @hp3 = FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[2].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: Range.new(@application_period.min.months_ago(3), @application_period.max.months_ago(3))))
    @hp4 = FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[3].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: Range.new(@application_period.min.months_ago(3), @application_period.max.months_ago(3))))
    @hp5 = FactoryBot.create(:benefit_markets_products_product, issuer_profile_id: issuer_profiles[3].issuer_profile.id, premium_tables: build_list(:benefit_markets_products_premium_table, 3, effective_period: @application_period))
    @hp1.reload
    @hp2.reload
    @hp3.reload
    @hp4.reload
    @hp5.reload
  end

  context "load_rates" do
    around do |example|
      ClimateControl.modify start_date: @end_date.next_month.beginning_of_month.strftime("%Y-%m-%d"), action: 'load_rates' do
        example.run
      end
    end

    pending "should load the dummy data"
    pending "should have premium_tables for dummy"
    pending "should have premium_tuples"

=begin
    it "should load the dummy data" do
      @hp1.premium_tables.where(:"effective_period.max" => @application_period.max.end_of_year.to_date).first.update_attributes(effective_period: @application_period)
      @hp1.reload
      expect(@hp1.premium_tables.count).to eq 4
      DummyPlanRatesLoaderSpecHelper.invoke_dummy_rates_tasks
      @hp1.reload
      expect(@hp1.premium_tables.count).to eq 8
    end

    it "should have premium_tables for dummy" do
      @hp1.premium_tables.where(:"effective_period.max" => @application_period.max.end_of_year.to_date).first.update_attributes(effective_period: @application_period)
      @hp1.reload
      DummyPlanRatesLoaderSpecHelper.invoke_dummy_rates_tasks
      @hp1.reload
      expect(@hp1.premium_tables.where(:"effective_period.min" => @application_period.max.next_month.beginning_of_month).count).to eq 4
    end

    it "should have premium_tuples" do
      DummyPlanRatesLoaderSpecHelper.invoke_dummy_rates_tasks
      @hp1.reload
      dummy1 = @hp1.premium_tables.where(:"effective_period.min" => @application_period.max.next_month.beginning_of_month)
      dummy1_pt = dummy1.first.premium_tuples

      expect(dummy1_pt.present?).to eq true
    end
=end
  end

  context "cleanup_rates" do
    around do |example|
      ClimateControl.modify start_date: @application_period.min.strftime("%Y-%m-%d"), action: 'cleanup_rates' do
        example.run
      end
    end

    pending "should cleanup the dummy data"
    pending "should not have premium_tables for dummy"

=begin
    it "should cleanup the dummy data" do
      expect(@hp1.premium_tables.where(:"effective_period.min" => @application_period.min).count).to eq 3
      DummyPlanRatesLoaderSpecHelper.invoke_dummy_rates_tasks
      @hp1.reload
      dummy_premium_tables = @hp1.premium_tables.where(:"effective_period.min" => @application_period.min)
      expect(@hp1.premium_tables.count).to eq 1
      expect(dummy_premium_tables.count).to eq 0
    end

    it "should not have premium_tables for dummy" do
      DummyPlanRatesLoaderSpecHelper.invoke_dummy_rates_tasks
      @hp1.reload
      expect(@hp1.premium_tables.where(:"effective_period.min" => @application_period.min).count).to eq 0
    end
=end
  end
end
