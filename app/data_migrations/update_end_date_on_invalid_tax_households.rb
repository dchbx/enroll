# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

#Rake to update invalid taxhouseholds due to end on is before start on. updating end on to start on.
class UpdateEndDateOnInvalidTaxHouseholds < MongoidMigrationTask
  def migrate
    Family.all_tax_households.no_timeout.each do |family|
      next if family.valid?

      family.active_household.tax_households.each do |tax_household|
        next if tax_household.effective_ending_on.nil?

        tax_household.update!(effective_ending_on: tax_household.effective_starting_on) if  tax_household.effective_ending_on < tax_household.effective_starting_on
      end
    rescue StandardError => e
      puts e.message
    end
  end
end