# require File.join(Rails.root, "lib/mongoid_migration_task")

class MapDentalPlans < MongoidMigrationTask

  def migrate
    previous_year = ENV["previous_year"]
    current_year = ENV["current_year"]

    previous_year_plans = Plan.dental_coverage.shop_market.where(active_year: previous_year)

    previous_year_plans.each do |old_plan|
      new_plan = Plan.dental_coverage.where(active_year: current_year, hios_id: old_plan.hios_id).first
      if new_plan.present?
        old_plan.update_attributes(renewal_plan_id: new_plan.id)
      end
    end
  end
end