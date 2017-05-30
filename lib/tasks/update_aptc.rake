namespace :update_aptc do
  desc "update applied aptc amount by elected amount in hbx_enrollments"
  task :applied_aptc_amount => :environment do 
    count = 0
    families = Family.gt("households.hbx_enrollments.elected_amount.cents"=> 0).to_a
    families.each do |family|
      households = family.households.gt("hbx_enrollments.elected_amount.cents"=> 0).to_a
      households.each do |household|
        hbxs = household.hbx_enrollments.gt("elected_amount.cents"=> 0).to_a
        hbxs.each do |hbx|
          if hbx.elected_amount > 0 and hbx.applied_aptc_amount == 0
            hbx.update_current(applied_aptc_amount: hbx.elected_amount.to_f) 
            count += 1
          end
        end
      end
    end
    puts "updated #{count} hbx_enrollments for applied_aptc_amount"
  end

  desc "update tax household member for Chanda Harris"
  task :certain_person => :environment do
    persons = Person.where(first_name: 'Chanda', last_name: 'harris')
    if persons.blank?
      puts "can not find person by name Chanda harris"
    else
      persons.each do |person|
        tax_household_members = person.primary_family.latest_household.latest_active_tax_household.tax_household_members rescue []
        tax_household_members.each do |tm|
          unless tm.is_primary_applicant?
            tm.is_ia_eligible = false
            tm.save
          end
        end
      end
      puts "finished updated for Chanda harris"
    end
  end
end
