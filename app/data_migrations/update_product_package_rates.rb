# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateProductPackageRates < MongoidMigrationTask
  def migrate
    feins = (ENV['feins']).to_s.split(',').uniq
    feins.each do |fein|
      organization = ::BenefitSponsors::Organizations::Organization.where(fein: fein).first
      benefit_applications = organization.employer_profile.benefit_applications.where(:aasm_state.in => BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES)
      if benefit_applications.count == 0
        puts "Found no Benefit Applications in PUBLISHED STATES" unless Rails.env.test?
      else
        benefit_applications.each do |ba|
          product_packages = ba.benefit_sponsor_catalog.product_packages
          product_packages.each do |product_package|
            hios_ids = product_package.products.map(&:hios_id).uniq
            products = ::BenefitMarkets::Products::Product.where(:hios_id.in => hios_ids).select{|a| a.active_year == 2018}
            product_package.products = products
            product_package.save
            puts "Product Package Updated for the fein => #{fein}"  unless Rails.env.test?
          end
        end
      end
    end
  rescue StandardError => e
    puts e.to_s
  end
end