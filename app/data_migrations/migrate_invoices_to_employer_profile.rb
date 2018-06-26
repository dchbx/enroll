require File.join(Rails.root, "lib/mongoid_migration_task")

class MigrateInvoicesToEmployerProfile < MongoidMigrationTask
  def migrate
    batch_size = 500
    offset = 0

    orgs = Organization.all_employer_profiles

    while (offset <= orgs.count)
      orgs.each do |org|
        begin
          invoices = org.documents.select{ |invoice| ["invoice", "initial_invoice"].include? invoice.subject }
          next if invoices.empty?
          puts "Found #{invoices.count} invoices for employer #{org.fein}" unless Rails.env.test?
          invoices.each do |invoice|
            org.employer_profile.documents << invoice
          end
          org.save!
          org.reload
          org.documents.select{ |invoice| (["invoice", "initial_invoice"].include? invoice.subject) && (org.employer_profile.documents.include?(invoice)) }.each{|doc| doc.delete}
          puts "Successfully migrated invoices from Organization to employer_profile for FEIN: #{org.fein}" unless Rails.env.test?
        rescue Exception => e
          log("#{e.message}; for employer with FEIN: #{org.fein}")
        end
      end
      offset = offset + batch_size
    end
  end
end