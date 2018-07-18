class UpdateMaListBillPricingModel < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      say_with_time("Correct raw pricing models") do
        correct_naked_pricing_model
      end
      say_with_time("Correct benefit market catalogs") do
        correct_benefit_market_catalogs
      end
      say_with_time("Correct benefit sponsor catalogs") do
        correct_benefit_sponsor_catalogs
      end
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
    raise "This migration can not be reversed!"
  end

  def self.correct_naked_pricing_model
    p_models = BenefitMarkets::PricingModels::PricingModel.where(name: /MA List Bill Shop Pricing Model/)
    say "Found #{p_models.count} matching Pricing Models"
    fix_count = 0
    p_models.each do |p_model|
      if update_price_model_relationships(p_model)
        fix_count = fix_count + 1
      end
    end
    say "Corrected #{fix_count} Pricing Models"
  end

  def self.correct_benefit_market_catalogs
    catalogs = BenefitMarkets::BenefitMarketCatalog.where({
      "product_packages" => {
        "$elemMatch" => {
            "pricing_model.name" => /MA List Bill Shop Pricing Model/,
            "pricing_model.member_relationships" => {
              "$elemMatch" => {
                "relationship_name" => "spouse",
                "relationship_kinds" => {"$nin" => ["domestic_partner"]}
              }
            }
        }
      }
    })
    say "Found #{catalogs.count} matching Benefit Market Catalogs"
    fix_count = 0
    catalogs.each do |cat|
      cat.product_packages.each do |p_package|
        if update_product_package(p_package)
          fix_count = fix_count + 1
        end
      end
    end
    say "Corrected #{fix_count} Benefit Market Catalog Pricing Models"
  end

  def self.correct_benefit_sponsor_catalogs
    catalogs = BenefitMarkets::BenefitSponsorCatalog.where({
      "product_packages" => {
        "$elemMatch" => {
            "pricing_model.name" => /MA List Bill Shop Pricing Model/,
            "pricing_model.member_relationships" => {
              "$elemMatch" => {
                "relationship_name" => "spouse",
                "relationship_kinds" => {"$nin" => ["domestic_partner"]}
              }
            }
        }
      }
    }).without("product_packages.products")
    say "Found #{catalogs.count} matching Benefit Sponsor Catalog"
    fix_count = 0
    catalogs.each do |cat|
      cat.product_packages.each do |p_package|
        if update_product_package(p_package)
          fix_count = fix_count + 1
        end
      end
    end
    say "Corrected #{fix_count} Benefit Sponsor Catalog Pricing Models"
  end

  def self.update_product_package(p_package)
    p_model = p_package.pricing_model
    relationship_mapping = p_model.member_relationships.detect { |mr| mr.relationship_name.to_s == "spouse" }
    existing_relationships = relationship_mapping.relationship_kinds.map(&:to_s)
    if existing_relationships.include?("domestic_partner")
      false
    else
      relationship_mapping.relationship_kinds = ["spouse", "life_partner", "domestic_partner"]
      # Fun caveat.  If you have a model that is both a top-level and embedded
      # document and you want to update it, you will need to write the PARENT
      # to ensure the changes 'stick'.
      p_package.save!
      true
    end
  end

  def self.update_price_model_relationships(p_model)
    relationship_mapping = p_model.member_relationships.detect { |mr| mr.relationship_name.to_s == "spouse" }
    existing_relationships = relationship_mapping.relationship_kinds.map(&:to_s)
    if existing_relationships.include?("domestic_partner")
      false
    else
      relationship_mapping.relationship_kinds = ["spouse", "life_partner", "domestic_partner"]
      p_model.save!
      true
    end
  end
end