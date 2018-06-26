require File.join(Rails.root, "lib/mongoid_migration_task")
 #This is going to update new plans creation
class UpdateAllPlanOptions < MongoidMigrationTask
  def migrate
    Plan.update_all(is_horizontal: true, is_vertical: true, is_sole_source: false)
    puts "successfully updated the plan attributes" unless Rails.env.test?
  end
end
