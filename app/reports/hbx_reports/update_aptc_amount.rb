require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAptcAmount < MongoidMigrationTask
  def migrate
    count = 0
    Family.all.each do |family|
      begin
        family.enrollments.by_year(2017).each do |en|
            ehb_premium = (en.plan.present? && en.plan.ehb > 0)? (en.total_premium * en.plan.ehb).round(2): en.total_premium
            if ehb_premium < en.applied_aptc_amount.to_f
                en.update_attribute("applied_aptc_amount", ehb_premium)
                puts "The applied_aptc_amount: #{en.applied_aptc_amount}, ehb_premium: #{ehb_premium} for hbx_id: #{en.hbx_id}" unless Rails.env.test?
                count += 1
            end
        end
      rescue
        puts "Bad family record #{family.id}"
      end
    end
    puts "Total number of updated records #{count}" unless Rails.env.test?
  end
end
