require File.join(Rails.root, "lib/mongoid_migration_task")

class Generate2017EhbReport < MongoidMigrationTask
  def migrate
    field_names  = %w(
        hbx_id
        enrollment_hbx_id
          )
    count = 0
    file_name = "#{Rails.root}/public/generate_2017_ehb_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
         csv << field_names
    Family.all.each do |family|
      begin
        family.enrollments.by_year(2017).each do |en|
          ehb_premium = (en.plan.present? && en.plan.ehb > 0)? (en.total_premium * en.plan.ehb).round(2): en.total_premium
          if ehb_premium < en.applied_aptc_amount.to_f
            csv << [
            family.primary_family_member.person.hbx_id,
            en.hbx_id
            ]
            count += 1
          end
        end
      rescue
        puts "Bad family record #{family.id}" unless Rails.env.test?
      end
    end
  end
    puts "Total number of updated records #{count}" unless Rails.env.test?
  end
end
