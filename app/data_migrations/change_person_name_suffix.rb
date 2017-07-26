require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePersonNameSuffix < MongoidMigrationTask
  def process_row(csv_row)
    person=Person.where(hbx_id: csv_row['HBX ID']).first rescue binding.pry
    correct_suffix = csv_row["Potential Correct Suffix"]
    if person.blank?
      puts "Person not found for the given HBX ID: #{csv_row["HBX_ID"]}" unless Rails.env.test?
    else
      person.update_attributes(name_sfx: correct_suffix)
      puts "Changed suffix of #{person.full_name} (HBX ID: #{person.hbx_id}) to #{correct_suffix}" unless Rails.env.test?
    end
  end

  def migrate
    filename = ENV['filename']

    CSV.foreach(filename, headers: true) do |csv_row|
      process_row(csv_row)
    end
  end
end
