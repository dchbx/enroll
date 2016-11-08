namespace :xml do
  task :standard_plans, [:file] => :environment do |task,args|

    puts "*"*80
    puts "Start of 2016 plans being updated to standard plans... "
    standard_hios_ids = ["94506DC0390001-01","94506DC0390005-01","94506DC0390007-01","94506DC0390011-01","86052DC0400001-01","86052DC0400002-01","86052DC0400007-01","86052DC0400008-01","78079DC0210001-01","78079DC0210002-01","78079DC0210003-01","78079DC0210004-01"]
    Plan.by_active_year(2016).where(:hios_id.in => standard_hios_ids).each do |plan|
      plan.update(is_standard_plan: true)
      puts "#{plan.active_year} #{plan.carrier_profile.legal_name} Plan with hios_id #{plan.hios_id} updated to standard plan."
    end
    puts "end of 2016 plans being updated to standard plans... "

    puts "*"*80
    puts "start of 2017 plans being updated to standard plans... "
    Plan.by_active_year(2017).each do |plan|
      if plan.name.downcase.include?("std") || plan.name.downcase.include?("standard")
        plan.update(is_standard_plan: true)
        puts "#{plan.active_year} #{plan.name}(#{plan.carrier_profile.legal_name}) Plan with hios_id #{plan.hios_id} updated to standard plan."
      end
    end
    puts "end of 2017 plans being updated to standard plans... "
    puts "*"*80
  end
end