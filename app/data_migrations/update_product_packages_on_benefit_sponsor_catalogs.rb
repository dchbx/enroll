# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateProductPackagesOnBenefitSponsorCatalogs < MongoidMigrationTask

  def migrate
    count = 0
    batch_size = 100
    offset = 0
    total_count = fetch_benefit_sponsorships.count
    puts "Total Benefit Sponsorships count #{total_count}" unless Rails.env.test?

    market_catalog = BenefitSponsors::Site.all.where(site_key: :dc).first.benefit_market_for(:aca_shop).benefit_market_catalog_for(Date.new(2020,1,1))

    while offset <= total_count
      fetch_benefit_sponsorships.offset(offset).limit(batch_size).no_timeout.each do |bs|
        bs.benefit_applications.where(:"effective_period.min" => Date.new(2020,1,1), :created_at.lte => Date.new(2019,10,30).beginning_of_day, :aasm_state.nin => [:draft, :canceled]).each do |ba|
          sponsor_catalog = ba.benefit_sponsor_catalog
          sponsor_catalog.product_packages.by_product_kind(:health).destroy_all
          sponsor_catalog.product_packages << market_catalog.product_packages.where(benefit_kind: :aca_shop, product_kind: :health).collect do |product_package|
            construct_sponsor_product_package(product_package, sponsor_catalog)
          end
          count += 1
          puts "Updated products packages for Employer #{bs.fein} ---- with benefit application state - #{ba.aasm_state}"  unless Rails.env.test?
        end
        puts "Total Number of applications updated #{count}"  unless Rails.env.test?
      rescue StandardError => e
        puts "Unable to create product packages for employer #{bs.fein} ---- #{e}" unless Rails.env.test?
      end
      offset += batch_size
    end
  end

  def fetch_benefit_sponsorships
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {:$elemMatch => {:"effective_period.min" => Date.new(2020,1,1), :created_at.lte => Date.new(2019,10,30).beginning_of_day,
                                                                                                             :aasm_state.nin => [:draft, :canceled]}})
  end

  def construct_sponsor_product_package(market_product_package, benefit_sponsor_catalog)
    product_package = BenefitMarkets::Products::ProductPackage.new(
      title: market_product_package.title,
      description: market_product_package.description,
      product_kind: market_product_package.product_kind,
      benefit_kind: market_product_package.benefit_kind,
      package_kind: market_product_package.package_kind
    )
    product_package.application_period = benefit_sponsor_catalog.effective_period
    product_package.contribution_model = market_product_package.contribution_model.create_copy_for_embedding
    product_package.pricing_model = market_product_package.pricing_model.create_copy_for_embedding
    product_package.products = market_product_package.load_embedded_products(benefit_sponsor_catalog.service_areas, benefit_sponsor_catalog.effective_period.min)
    product_package
  end
end
