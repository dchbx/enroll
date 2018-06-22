require File.join(Rails.root, "lib/mongoid_migration_task")

class ReactivateTaxHouseholdWithAssistanceYear < MongoidMigrationTask
  def migrate
    primary_person_hbx_id = ENV['primary_person_hbx_id']
    applicable_year = ENV['applicable_year'].to_i
    max_aptc = ENV['max_aptc']
    csr_percent = ENV['csr_percent'].to_i
    primary_person = Person.where(hbx_id: primary_person_hbx_id, is_active: true).first
    if primary_person
      begin
        tax_households = primary_person.primary_family.active_household.tax_households.tax_household_with_year(applicable_year).select do |thh|
          ed = thh.latest_eligibility_determination
          ed && ed.max_aptc.to_f == max_aptc.to_f && ed.csr_percent_as_integer == csr_percent
        end

        tax_households.sort { |a, b|  a.created_at <=> b.created_at }.last.update_attributes!(effective_ending_on: nil) if tax_households.present?
      rescue => e
        puts "Could not update tax_household for this reason: #{e}" unless Rails.env.test?
      end
    else
      puts "Please pass correct hbx_ids as respective arguments" unless Rails.env.test?
    end
  end
end
