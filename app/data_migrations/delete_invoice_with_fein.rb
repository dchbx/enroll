require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteInvoiceWithFein < MongoidMigrationTask
  
  def self.get_orgs(feins)
    feins = feins.split(",")
    Organization.where("fein" => {"$in" => feins}).entries
  end

  def self.migrate(feins)
    orgs = get_orgs(feins)
    delete_invoice(orgs)
  end

  def self.delete_invoice(orgs)
    current_date =TimeKeeper.date_of_record
    orgs.each do |org|
      invoice = org.invoices.detect{|invoice| invoice.date.try(:month) ==current_date.month && invoice.date.try(:year) ==  current_date.year  }
      invoice.destroy if invoice
    end
  end
end