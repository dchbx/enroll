namespace :xml do
  task :update_united_plan_name, [:file] => :environment do |task,args|
    plan = Plan.where(active_year: 2017, hios_id: /21066DC0010017-01/).first
    puts "Updating united plan name with hios_id #{plan.hios_id}" unless Rails.env.test?
    plan.name = "UHC Navigate HMO Gold 500"
    plan.save
    qhp = Products::Qhp.where(standard_component_id: plan.hios_base_id).last
    qhp.plan_marketing_name = plan.name
    qcsv = qhp.qhp_cost_share_variances.first
    qcsv.plan_marketing_name = plan.name
    qhp.save
    puts "successfully updated united plan name to #{plan.name} with hios_id #{plan.hios_id}" unless Rails.env.test?
  end
end