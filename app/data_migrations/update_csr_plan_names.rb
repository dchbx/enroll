require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCsrPlanNames < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    puts "updating csr plan names" unless Rails.env.test?

    hios_base_ids = [
      "94506DC0390004", "94506DC0390005", "94506DC0390006", "86052DC0400001",
      "78079DC0210004", "86052DC0400007", "86052DC0400002", "86052DC0400008",
      "78079DC0210001", "78079DC0210003", "78079DC0210002"
    ]


    hios_base_ids.each do |hios_id|
      Products::Qhp.where(active_year: 2017, standard_component_id: hios_id).each do |qhp|
        qhp.qhp_cost_share_variances.each do |qcsv|
          plan = Plan.where(active_year: 2017, hios_id: qcsv.hios_plan_and_variant_id).first
          plan.name = qcsv.plan_marketing_name
          plan.save
          unless Rails.env.test?
            puts "updated plan name to -> #{plan.name} :: for #{plan.hios_id} "
          end
        end
      end
    end
  end
end
