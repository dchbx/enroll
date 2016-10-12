namespace :update do
  desc "Update hsa_eligibility of plans"
  task :hsa_eligibility => :environment do
    puts "*"*80
    puts "starting the process to update hsa_eligibility for plans"
    count = 0
    Plan.where(:active_year.gt => 2014).health_coverage.each do |plan|
      qhp = Products::Qhp.by_hios_ids_and_active_year([plan.hios_base_id], plan.active_year).first
      plan.hsa_eligibility = qhp.hsa_eligibility
      count += 1
      plan.save
    end
    puts "successfully updated hsa_eligibility for #{count} plans"
    puts "*"*80
  end
end
