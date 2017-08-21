# RAILS_ENV=production bundle exec rake migrations:add_new_eligibility_determination hbx_id=477894 effective_date="08/01/2017" max_aptc=200000 csr_percent_as_integer=73
require File.join(Rails.root, "lib/mongoid_migration_task")
class AddNewEligibilityDetermination < MongoidMigrationTask
    def migrate
      person = Person.where(hbx_id:ENV['hbx_id'])
      if person.size==0
        puts "No person was found with the given hbx_id" #unless Rails.env.test?
        return
      elsif person.size > 1
        puts "More than one person was found with the given hbx_id" #unless Rails.env.test?
        return
      end
      if person.first.primary_family.nil?
        puts "No primary_family exists for person with the given hbx_id" unless Rails.env.test?
        return
      end
      primary_family = person.first.primary_family

      if primary_family.active_household.nil?
        puts "No active household  exists for person with the given hbx_id" unless Rails.env.test?
        return
      end
      active_household= primary_family.active_household
      if  active_household.latest_active_tax_household.nil?
        puts "No active tax household  exists for person with the given hbx_id" unless Rails.env.test?
        return
      end

      date = Date.strptime(ENV['effective_date'].to_s, "%m/%d/%Y")

      latest_active_household = active_household.latest_active_tax_household
      latest_eligibility_determination = latest_active_household.latest_eligibility_determination
      latest_active_household.eligibility_determinations.build({"determined_at"                 => date,
                                                                "determined_on"                 => date,
                                                                "csr_eligibility_kind"          => latest_eligibility_determination.csr_eligibility_kind,
                                                                "premium_credit_strategy_kind"  => latest_eligibility_determination.premium_credit_strategy_kind,
                                                                "csr_percent_as_integer"        => ENV['csr_percent_as_integer'],
                                                                "max_aptc"                      => {"cents"=> ENV['max_aptc'].to_f*100, "currency_iso"=>"USD"},
                                                                "benchmark_plan_id"             => latest_eligibility_determination.benchmark_plan_id,
                                                                "e_pdc_id"                      => latest_eligibility_determination.e_pdc_id,
                                                                "source"                        => "Admin"
                                                                }).save!
      puts "Create eligibility_determinations for person with the given hbx_id #{ENV['hbx_id']}" unless Rails.env.test?
    end
end
