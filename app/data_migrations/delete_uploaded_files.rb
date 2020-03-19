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
    field_names = %w[First_Name Last_Name HBX_ID]
    file_name = "#{Rails.root}/list_of_people_uploaded_files_deleted.csv"

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      Person.where(:"consumer_role.vlp_documents".exists => true).no_timeout.inject([]) do |_dummy, person|
        uploaded_files = person.consumer_role.vlp_documents.where(:verification_type.exists => true)
        if uploaded_files.present?
          uploaded_files.delete_all
          csv << [person.first_name, person.last_name, person.hbx_id]
        end
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end
end
