# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
# This migration is delete the uploaded files from the model VLP Documents(Under Consumer Role)
# as they were copied to a new model under Verification Type as part of CADC Part 2 project.
# We have to delete because the purpose of the VLP Document model embedded under Consumer Role
# is purely to store information about the Immigration Lawful Presence Types and not to
# store uploaded files anymore(part of CADC part 2).
# Reference: app/data_migrations/migrate_verification_types.rb

class DeleteUploadedFiles < MongoidMigrationTask
  def migrate
    field_names = %w[First_Name Last_Name HBX_ID Verification_Type Identifier Title Subject Created_At Updated_At]
    file_name = "#{Rails.root}/list_of_people_uploaded_files_deleted.csv"
    vlp_doc_types = ::VlpDocument::VLP_DOCUMENT_KINDS + ['Other (With I-94)']

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      Person.where(:"consumer_role.vlp_documents.verification_type".exists => true).no_timeout.inject([]) do |_dummy, person|
        uploaded_files = person.consumer_role.vlp_documents.where(:verification_type.exists => true,
                                                                  :identifier.ne => nil,
                                                                  :subject.nin => vlp_doc_types)
        uploaded_file_ids = uploaded_files.inject([]) do |file_ids, uploaded_file|
          file_ids << uploaded_file.id if uploaded_file.verification_type.present? && uploaded_file.identifier.present? && !vlp_doc_types.include?(uploaded_file.subject)
          file_ids
        end
        uploaded_file_ids.each do |file_id|
          file = uploaded_files.where(id: file_id.to_s).first
          next unless file.present?
          csv << [person.first_name, person.last_name, person.hbx_id,
                  file.verification_type, file.identifier, file.title,
                  file.subject, file.created_at, file.updated_at]
          file.delete
        end
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end
end

