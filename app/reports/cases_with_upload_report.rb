require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class CasesWithUploadReport< MongoidMigrationTask
    def migrate

      people=Person.where("consumer_role.aasm_state"=>"verification_outstanding").where("consumer_role.vlp_documents.status"=>"downloaded")
      people.count
      people.map{|a| puts "#{a.first_name}, #{a.last_name}, #{a.hbx_id}"}
      field_names  = %w(first name,last name, hbx_id)
      file_name = "#{Rails.root}/public/cases_with_upload_report_spect.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        people.each do |person|
          csv << [
              person.first_name,
              person.last_name,
              person.hbx_id
          ]
        end
      end
    end
end




