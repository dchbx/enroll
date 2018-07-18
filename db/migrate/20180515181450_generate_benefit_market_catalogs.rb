class GenerateBenefitMarketCatalogs < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      say_with_time("Loading MA benefit market catalog") do
        require File.join(Rails.root, "db/seedfiles/ma_benefit_market_catalogs_product_packages")
      end
    else
      say("Skipping migration for non-MHC site")
    end
  end

  def self.down
    if Settings.site.key.to_s == "cca"
      BenefitMarkets::BenefitMarketCatalog.all.delete
      BenefitMarkets::Products::ProductPackage.all.delete
    else
      say("Skipping migration for non-MHC site")
    end
  end
end