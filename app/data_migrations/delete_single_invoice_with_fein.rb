# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class DeleteSingleInvoiceWithFein < MongoidMigrationTask
  def migrate
    fein = ENV['fein']
    date = Date.strptime(ENV['date'], "%m/%d/%Y")
    organization = ::BenefitSponsors::Organizations::Organization.where(fein: fein)
    return puts "Fein has more than one organization or no organization to it" if organization.size != 1 && !Rails.env.test?
    invoice = organization.first.employer_profile.invoices.detect{|invoice| invoice.date == date && invoice.subject == 'initial_invoice' }
    invoice&.destroy
    puts "invoice for #{date} has been deleted successfully" unless Rails.env.test?
  end
end