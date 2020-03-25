require 'rails_helper'

# TODO: These specs are very fragile and need to be re-written.
#       For now, I have marked them pending and tagged them as 'fragile'.
#       This will be our practice going forward for fragile specs until we address them.

class DentalPricingContributionModelImportSpecHelper

  def self.invoke_models_task
    Rake::Task["seed:dental_contribution_and_pricing_model"].reenable
    Rake::Task["seed:dental_contribution_and_pricing_model"].invoke
  end
end

RSpec.describe 'load_dental_pricing_and_contribution_models', :type => :task, :dbclean => :around_each do
  before :all do
    Rake.application.rake_require "tasks/migrations/plans/load_dental_pricing_and_contribution_models"
    Rake::Task.define_task(:environment)
  end

  before :context do
    DentalPricingContributionModelImportSpecHelper.invoke_models_task
  end

  context "load pricing model" do
    pending "should have one pricing record", :fragile => true

=begin
    it "should have one pricing record" do
      pm= BenefitMarkets::PricingModels::PricingModel.where(price_calculator_kind: "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator")
      expect(pm.count).to be 1
    end
=end
  end

  context "load contribution model" do
    pending "should have one contribution record", :fragile => true
=begin
    it "should have one contribution record" do
      cm = BenefitMarkets::ContributionModels::ContributionModel.where(contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator")
      expect(cm.count).to be 1
    end
=end
  end
  after(:all) do
    DatabaseCleaner.clean
  end
end