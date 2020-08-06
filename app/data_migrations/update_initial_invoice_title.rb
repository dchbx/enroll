# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateInitialInvoiceTitle < MongoidMigrationTask
  def migrate
    BenefitSponsors::Organizations::Organization.where(:"profiles._type" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile").all.each do |org|
      invoices = org.employer_profile.invoices
      next unless invoices.present?
      initial_invoices = invoices.select { |i| i.subject == "initial_invoice" }
      next unless initial_invoices.present?
      initial_invoices.each do |inv|
        if inv.title.exclude?("pdf")
          inv.update_attributes!(title: "Initial_Invoice_Now_Available.pdf")
          puts "Update initial invoice title for #{org.legal_name}" unless Rails.env.test?
        end
      end
    end
  end
end
