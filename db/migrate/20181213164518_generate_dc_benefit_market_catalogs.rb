class GenerateDcBenefitMarketCatalogs < Mongoid::Migration
  def self.up
    # TODO update pricing and contribution for fehb & shop market.
    if Settings.site.key.to_s == "dc"
      say_with_time("Loading DC benefit market catalog") do
        require File.join(Rails.root, "db/seedfiles/dc_benefit_market_catalogs_product_packages")
      end
    else
      say("Skipping migration for non-DC site")
    end
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      BenefitMarkets::BenefitMarketCatalog.all.delete
      BenefitMarkets::Products::ProductPackage.all.delete
    else
      say("Skipping migration for non-DC site")
    end
  end
end