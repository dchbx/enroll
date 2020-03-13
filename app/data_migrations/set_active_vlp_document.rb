# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
# This migration is to set a field called active_vlp_document_id on Consumer Role model to
# dictate which of the Verification Lawful Presence Determination types is active

class SetActiveVlpDocument < MongoidMigrationTask
  def fetch_latest_vlp_document(consumer_role)
    naturalized_citizen_docs = ['Certificate of Citizenship', 'Naturalization Certificate']
    # Had to consider 'Other (With I-94)' because of current Production bug 85769.
    docs_for_status = consumer_role.citizen_status == 'naturalized_citizen' ? naturalized_citizen_docs : (VlpDocument::VLP_DOCUMENT_KINDS + ['Other (With I-94)'])
    docs_for_status_uploaded = consumer_role.vlp_documents.where(:subject => {"$in" => docs_for_status})
    docs_for_status_uploaded.any? ? docs_for_status_uploaded.order_by(:updated_at => 'desc').first : nil
  end

  def migrate
    field_names = %w[First_Name Last_Name HBX_ID Updated_VLP_Document_Type]
    file_name = "#{Rails.root}/set_active_vlp_document_list.csv"

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names

      Person.where(:"consumer_role.vlp_documents".exists => true).no_timeout.inject([]) do |_dummy, person|
        vlp_doc = fetch_latest_vlp_document(person.consumer_role)
        raise "Valid VLP Documents not not found for person: #{person.hbx_id}, invalid_vlp_docs: #{person.consumer_role.vlp_documents.map(&:subject)}" unless vlp_doc
        person.consumer_role.update_attributes!(active_vlp_document_id: vlp_doc.id)
        csv << [person.first_name, person.last_name, person.hbx_id, vlp_doc.subject]
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end
end
