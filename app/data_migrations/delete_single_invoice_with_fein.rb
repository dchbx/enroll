require File.join(Rails.root, "lib/mongoid_migration_task")
class DeleteSingleInvoiceWithFein < MongoidMigrationTask
  def migrate
    fein = ENV['fein']
    date = Date.strptime(ENV['date'], "%m/%d/%Y")
    organization = Organization.where(fein: fein)
    return puts "Fein has more than one organization or no organization to it" if organization.size != 1 && !Rails.env.test?
    invoice = organization.first.documents.detect{|invoice| invoice.date == date && invoice.subject == 'invoice' }
    invoice.destroy if invoice
    puts "invoice for #{date} has been deleted successfully" if invoice.destroy && !Rails.env.test?
  end
end