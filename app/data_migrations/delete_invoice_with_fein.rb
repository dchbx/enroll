# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteInvoiceWithFein < MongoidMigrationTask

  def get_orgs(feins)
    feins = feins.split(",")
    BenefitSponsors::Organizations::Organization.where("fein" => {"$in" => feins}).entries
  end

  def migrate
    feins = ENV['feins']
    orgs = get_orgs(feins)

    puts 'No organizations are present' if orgs.blank?

    delete_initial_employer_invoice_notice(orgs)
    delete_message_from_inbox(orgs)
    delete_invoice(orgs)
  end

  def delete_invoice(orgs)
    current_date = TimeKeeper.date_of_record
    orgs.each do |org|
      invoice = org.employer_profile.documents.detect{|invoice| invoice.date.try(:month) == current_date.month && invoice.date.try(:year) == current_date.year  }
      invoice&.destroy
    end
  end

  def delete_initial_employer_invoice_notice(orgs)
    orgs.each do |org|
      documents = org.employer_profile.documents.select{|document| document.title == "Your_Invoice_Is_Now_Available_In_Your_#{EnrollRegistry[:enroll_app].setting(:short_name).item.parameterize.underscore}_Account" }
      next if documents.blank?

      documents.map(&:destroy)
    end
  end

  def delete_message_from_inbox(orgs)
    orgs.each do |org|
      messages = org.employer_profile.inbox.messages.select{|message| message.subject == "Your Invoice is Now Available in your #{EnrollRegistry[:enroll_app].setting(:short_name).item} Account" }
      next if messages.blank?

      messages.map(&:destroy)
    end
  end
end