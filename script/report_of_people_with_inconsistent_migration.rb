# frozen_string_literal: true

# This is a report of people without migrated Uploaded Files as part of CADC-Phase II 
field_names = %w[HBX_ID First_Name Last_Name Verification_Type Uploaded_file_title]
file_name = "#{Rails.root}/report_of_people_with_inconsistent_migration_86296.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  Person.where(:'consumer_role.vlp_documents.verification_type'.exists => true).inject([]) do |_dummy, person|
    person.consumer_role.vlp_documents.where(:verification_type.exists => true).each do |uploaded_file|
      puts "Uploaded File Verification Type: #{uploaded_file.verification_type}"
      verification_type = person.consumer_role.verification_types.where(type_name: uploaded_file.verification_type).first
      document_v_type = verification_type.vlp_documents.where(title: uploaded_file.title).first
      if document_v_type
        puts "Matching Uploaded File exists for #{uploaded_file.title}, person: #{person.hbx_id}"
      else
        puts "NO Matching Uploaded File exists for #{uploaded_file.title}, person: #{person.hbx_id}"
        csv << [person.hbx_id, person.first_name, person.last_name, uploaded_file.verification_type, uploaded_file.title]
      end
    rescue StandardError => e
      puts e.message
    end
  rescue StandardError => e
    puts e.message
  end
end

