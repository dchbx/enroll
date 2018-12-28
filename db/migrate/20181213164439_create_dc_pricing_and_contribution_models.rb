class CreateDcPricingAndContributionModels < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      require File.expand_path(File.join(Rails.root, "db/seedfiles/dc/pricing_and_contribution_models_seed"))
      say_with_time("Load DC Pricing Models") do
        load_dc_shop_pricing_models_seed
      end
      say_with_time("Load DC Contribution Models") do
        load_dc_shop_contribution_models_seed
      end
    else
      say("Skipping migration for non-DC site")
    end
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      ::BenefitMarkets::PricingModels::PricingModel.all.delete_all
      ::BenefitMarkets::ContributionModels::ContributionModel.all.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end
end