# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateListBillContributionUnits < MongoidMigrationTask

  def migrate
    contribution_model = BenefitMarkets::ContributionModels::ContributionModel.by_title("DC Shop Simple List Bill Contribution Model")
    contribution_model.contribution_units.each do |contribution_unit|
      if contribution_unit.name == 'employee'
        contribution_unit.default_contribution_factor = 0.5
        contribution_unit.minimum_contribution_factor = 0.5
      else
        contribution_unit.default_contribution_factor = 0.0
        contribution_unit.minimum_contribution_factor = 0.0
      end
    end
    contribution_model.save
  end
end