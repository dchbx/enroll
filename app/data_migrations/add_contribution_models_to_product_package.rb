# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class AddContributionModelsToProductPackage < MongoidMigrationTask

  def migrate
    date = Date.new(2021,1,1)
    puts "creating contribution models for year #{date.year}" unless Rails.env.test?
    site = BenefitSponsors::Site.by_site_key(EnrollRegistry[:enroll_app].setting(:site_key).item).first

    title_percentage_pair = {
      zero_percent_sponsor_fixed_percent_contribution_model: 0.0,
      fifty_percent_sponsor_fixed_percent_contribution_model: 0.5
    }

    benefit_market = site.benefit_markets.where(kind: :aca_shop).first
    benefit_market_catalog = benefit_market.benefit_market_catalogs.by_application_date(date).first

    raise "Unable to find benefit market catalog for the #{date.to_date}" unless benefit_market_catalog

    benefit_market_catalog.product_packages.each do |product_package|
      next unless product_package.product_kind == :health
      product_package.contribution_models = title_percentage_pair.collect do |title, pct|
        contribution_model = create_contribution_model(product_package.contribution_model)
        update_title_and_contribution_percentages(contribution_model, title, pct)
      end
      product_package.save
    end

    benefit_market_catalog.save!
    puts "created contribution models for year #{date.year}"  unless Rails.env.test?
  end

  def create_contribution_model(contribution_model)
    new_contribution_model = contribution_model.class.new(contribution_model.attributes.except(:_id, :contribution_units, :member_relationships))
    new_contribution_model.contribution_units = contribution_model.contribution_units.collect{ |contribution_unit| contribution_unit.class.new(contribution_unit.attributes.except(:_id)) }
    new_contribution_model.member_relationships = contribution_model.member_relationships.collect{ |mr| mr.class.new(mr.attributes.except(:_id)) }
    new_contribution_model
  end

  def update_title_and_contribution_percentages(contribution_model, title, pct)
    contribution_model.title = title.to_s.humanize.titleize
    contribution_model.key = title.to_s.parameterize(separator: '_').to_sym

    contribution_model.contribution_units.each do |contribution_unit|
      if contribution_unit.name == 'employee'
        contribution_unit.default_contribution_factor = pct
        contribution_unit.minimum_contribution_factor = pct
      else
        contribution_unit.default_contribution_factor = 0.0
        contribution_unit.minimum_contribution_factor = 0.0
      end
    end
    contribution_model
  end
end
