# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class FixEdSourceCuramCases < MongoidMigrationTask

  def process_families(families, file_name, offset_count)
    field_names = %w[person_hbx_id ed_object_id source e_pdc_id]
    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
        person = family.primary_person
        family.active_household.tax_households.where(:"eligibility_determinations.e_pdc_id".ne => nil).each do |thh|
          thh.eligibility_determinations.where(:e_pdc_id.ne => nil).each do |ed|
            next ed if ed.e_pdc_id.include?('MANUALLY')

            ed.update_attributes!(source: 'Curam')
            csv << [person.hbx_id, ed.id, ed.source, ed.e_pdc_id]
          end
        end
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end

  def migrate
    start_time = DateTime.current
    puts "FixEdSourceCuramCases start_time: #{start_time}" unless Rails.env.test?
    families = Family.where(:"households.tax_households.eligibility_determinations.e_pdc_id".ne => nil)
    total_count = families.count
    familes_per_iteration = 10_000.0
    number_of_iterations = (total_count / familes_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      file_name = "#{Rails.root}/list_of_ed_object_ids_for_curam_cases_#{counter + 1}.csv"
      offset_count = familes_per_iteration * counter
      process_families(families, file_name, offset_count)
      counter += 1
    end
    end_time = DateTime.current
    puts "FixEdSourceCuramCases end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}" unless Rails.env.test?
  end
end
