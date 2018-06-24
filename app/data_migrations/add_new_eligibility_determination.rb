# RAILS_ENV=production bundle exec rake migrations:add_new_eligibility_determination hbx_id=477894 effective_date="08/01/2017" max_aptc=200000 csr_percent_as_integer=73
require File.join(Rails.root, "lib/mongoid_migration_task")
class AddNewEligibilityDetermination < MongoidMigrationTask
    def migrate
      people=get_people
      people.each do |person|
        if person.primary_family.nil? || person.primary_family.active_household.nil? || person.primary_family.active_household.latest_active_tax_household.nil?
          puts "No primary_family or active househod or latest_active_household exists for person with the given hbx_id #{person.hbx_id}" unless Rails.env.test?
          return
        end
        active_household= person.primary_family.active_household
        date = Date.strptime(ENV['effective_date'].to_s, "%m/%d/%Y")
        if active_household.latest_active_tax_household_with_year(date.year).nil?
          latest_active_tax_household = active_household.latest_active_tax_household
        else
          latest_active_tax_household = active_household.latest_active_tax_household_with_year(date.year)
        end
        latest_eligibility_determination = latest_active_tax_household.latest_eligibility_determination
        latest_active_tax_household.eligibility_determinations.build({"determined_at"                 => date,
                                                                "determined_on"                 => date,
                                                                "csr_eligibility_kind"          => latest_eligibility_determination.csr_eligibility_kind,
                                                                "premium_credit_strategy_kind"  => latest_eligibility_determination.premium_credit_strategy_kind,
                                                                "csr_percent_as_integer"        => ENV['csr_percent_as_integer'],
                                                                "max_aptc"                      => {"cents"=> ENV['max_aptc'].to_f*100, "currency_iso"=>"USD"},
                                                                "benchmark_plan_id"             => latest_eligibility_determination.benchmark_plan_id,
                                                                "e_pdc_id"                      => latest_eligibility_determination.e_pdc_id,
                                                                "source"                        => "Admin"
                                                                }).save!
        puts "Create eligibility_determinations for person with the given hbx_id #{person.hbx_id}" unless Rails.env.test?
      end
    end
    def get_people
      hbx_ids = "#{ENV['hbx_id']}".split(',').uniq
      hbx_ids.inject([]) do |people, hbx_id|
        if Person.where(hbx_id:hbx_id).size != 1
          puts "No person was found with the given hbx_id #{hbx_id}" #unless Rails.env.test?
        else
          people << Person.where(hbx_id:hbx_id).first
        end
      end
    end
end
