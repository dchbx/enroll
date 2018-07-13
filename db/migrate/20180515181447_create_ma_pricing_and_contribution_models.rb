class CreateMaPricingAndContributionModels < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      require File.expand_path(File.join(Rails.root, "db/seedfiles/cca/pricing_and_contribution_models_seed"))
      say_with_time("Load MA Pricing Models") do
        load_cca_pricing_models_seed
      end
      say_with_time("Load MA Contribution Models") do
        load_cca_contribution_models_seed
      end
    else
      say("Skipping migration for non-MHC site")
    end
  end

  def self.down
    raise "Migration is not reversible."
  end
end
