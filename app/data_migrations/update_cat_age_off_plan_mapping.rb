require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCatAgeOffPlanMapping < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    kaiser_age_off = Plan.where(active_year: 2017, hios_id: /94506DC0390012/).last
    carefirst_age_off = Plan.where(active_year: 2017, hios_id: /86052DC0400007/).last
    puts "cat age of mapping started" unless Rails.env.test?

    Plan.where(active_year: 2016, metal_level: "catastrophic").each do |old_plan|
      new_plan = Plan.where(active_year: 2017, metal_level: "catastrophic", hios_id: old_plan.hios_id).first
      old_plan.renewal_plan_id = new_plan.id
      old_plan.cat_age_off_renewal_plan_id = if old_plan.hios_base_id == "94506DC0390008"
        kaiser_age_off.id
      else
        carefirst_age_off.id
      end
      old_plan.save
    end
    puts "cat age of mapping finished" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end
