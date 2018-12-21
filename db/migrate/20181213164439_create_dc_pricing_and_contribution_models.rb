class CreateDcPricingAndContributionModels < Mongoid::Migration
  def self.up
    # TODO Need to create Pricing & Contribution model for congress check with trey
    if Settings.site.key.to_s == "dc"
      require File.expand_path(File.join(Rails.root, "db/seedfiles/cca/pricing_and_contribution_models_seed"))
      say_with_time("Load DC Pricing Models") do
        load_cca_pricing_models_seed
      end
      say_with_time("Load DC Contribution Models") do
        load_cca_contribution_models_seed
      end
    else
      say("Skipping migration for non-DC site")
    end
  end

  def self.down
    raise "Migration is not reversible."
  end
end