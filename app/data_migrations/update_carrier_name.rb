require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierName < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    puts "Updating carrier legal name." unless Rails.env.test?

    org = Organization.where(fein: ENV["fein"]).last
    org.update_attributes(legal_name: ENV["name"]) if org.present?

    puts "Successfully updated carrier legal name -> #{org.legal_name}" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end
