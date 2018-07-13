require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveSuppressedFallonPlans < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    puts "Deleting suppressed fallon plans" unless Rails.env.test?

    hios_base_ids = ["88806MA0020005", "88806MA0040005", "88806MA0020051", "88806MA0040051"]
    Plan.where(:hios_base_id.in => hios_base_ids).delete_all
    Products::Qhp.where(:standard_component_id.in => hios_base_ids).delete_all

    puts "successfully deleted suppressed fallon plans" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end

