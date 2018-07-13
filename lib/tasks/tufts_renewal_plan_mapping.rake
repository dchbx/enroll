namespace :map do

  desc "Update tufts premier plan mappings"
  task :tufts_premier_plans => :environment do

    h = {
      "29125MA0030112-01" => "36046MA0700062-01",
      "29125MA0030113-01" => "36046MA0700063-01",
      "29125MA0030114-01" => "36046MA0700064-01",
      "29125MA0030116-01" => "36046MA0700065-01"
    }

    h.each do |k,v|
      plan = Plan.where(active_year: 2017, hios_id: k).first
      rm = RenewalPlanMapping.new(
        start_on: Date.new(2018,1,1),
        end_on: Date.new(2018,06,30),
        renewal_plan_id: Plan.where(active_year: 2018, hios_id: v).last.id
        )
      plan.renewal_plan_mappings << rm
      plan.save
    end

  end
end