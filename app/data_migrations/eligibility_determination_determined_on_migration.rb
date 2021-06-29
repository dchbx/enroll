# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# NOTE: Even after this migration is run, the determined_on field
# should NOT BE REMOVED
class EligibilityDeterminationDeterminedOnMigration < MongoidMigrationTask
  def migrate
    field_names = %w[Enrolled_Member_HBX_ID EligibilityDetermination_bson_object_id]
    families = Family.all_eligible_for_assistance
    if families.blank?
      puts("No families with eligbility determinations present.") unless Rails.env.test?
      nil
    else
      processed_count = 0
      file_name = "#{Rails.root}/eligibility_determination_migration_report.csv"
      FileUtils.touch(file_name) unless File.exist?(file_name)
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << field_names
        families.each do |family|
          family.households.each do |household|
            household.tax_households.each do |tax_household|
              tax_household.eligibility_determinations.each do |determination|
                next unless determination.determined_on.present?
                # Update before sending to CSV
                # determined_at is the proper field name
                determination.update_attributes!(determined_at: determination.determined_on)
                csv << [family&.primary_person&.hbx_id.to_s, determination._id.to_s]
                processed_count += 1
              end
            end
          end
        end
      end
      puts("Total eligibility determinations with deprecated determined_on field are #{processed_count}. HBX and EligibilityDetermination MongoId outputted to: #{file_name}") unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.message
  end
end
