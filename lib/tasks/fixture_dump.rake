namespace :fixture_dump do
  desc "Dump the carrier organizations"
  task :issuer_profiles => :environment do
    ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ip_org|
      f_name = File.join(Rails.root, "fixture_dumps", "issuer_profile_#{ip_org.hbx_id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write ip_org.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the site"
  task :site => :environment do
    ::BenefitSponsors::Site.each do |site|
      f_name = File.join(Rails.root, "fixture_dumps", "site_#{site.site_key}.yaml")
      File.open(f_name,'w') do |f|
        f.write site.to_yaml(except: ["__selected_fields"])
      end
    end
    ::BenefitSponsors::Organizations::Organization.where({site_owner_id: {"$ne" => nil}}).each do |site|
      f_name = File.join(Rails.root, "fixture_dumps", "owner_organization_#{site.hbx_id}.yaml")
      File.open(f_name,'w') do |f|
        f.write site.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the county-zips"
  task :county_zips => :environment do
    ::BenefitMarkets::Locations::CountyZip.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "county_zips_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the rating areas"
  task :rating_areas => :environment do
    ::BenefitMarkets::Locations::RatingArea.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "rating_area_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the service areas"
  task :service_areas => :environment do
    ::BenefitMarkets::Locations::ServiceArea.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "service_area_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the actuarial factors"
  task :factors => :environment do
    ::BenefitMarkets::Products::ActuarialFactors::ActuarialFactor.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "actuarial_factor_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump the products"
  task :products => :environment do
    ::BenefitMarkets::Products::Product.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "product_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump sic codes"
  task :sic_codes => :environment do
    ::SicCode.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "sic_code_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump pricing and contribution models"
  task :pricing_and_contribution_models => :environment do
    ::BenefitMarkets::PricingModels::PricingModel.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "pricing_model_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
    ::BenefitMarkets::ContributionModels::ContributionModel.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "contribution_model_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump QLEs"
  task :qles=> :environment do
    ::QualifyingLifeEventKind.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "qle_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "Dump Translations"
  task :translations => :environment do
    ::Translation.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "translation_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "dump benefit markets"
  task :benefit_markets => :environment do
    ::BenefitMarkets::BenefitMarket.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "benefit_market_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "dump data_migrations"
  task :data_migrations => :environment do
    DataMigration.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "data_migration_#{cz.version.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
  desc "dump benefit_market_catalogs"
  task :benefit_market_catalogs => :environment do
    BenefitMarkets::BenefitMarketCatalog.each do |cz|
      f_name = File.join(Rails.root, "fixture_dumps", "benefit_market_catalog_#{cz.id.to_s}.yaml")
      File.open(f_name,'w') do |f|
        f.write cz.to_yaml(except: ["__selected_fields"])
      end
    end
  end
end
