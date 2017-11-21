require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class BrokersNotActiveStatusReport < MongoidMigrationTask
  def migrate
    field_names  = %w( ER_Name DBA FEIN Broker_Agency Broker_Name Current_Status)

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/brokers_not_active_status_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      Person.all.each do |person|
        begin
          if person.broker_role.present?
            if person.broker_role.aasm_state != "active"
              if person.broker_role.broker_agency_profile.present?
                if  person.broker_role.broker_agency_profile.employer_clients.present?
                  person.broker_role.broker_agency_profile.employer_clients.each do |employer_client|
                    csv << [
                      employer_client.legal_name,
                      employer_client.dba,
                      employer_client.fein,
                      person.broker_role.broker_agency_profile.legal_name,
                      person.full_name,
                      person.broker_role.aasm_state
                    ]

                    if person.broker_role.broker_agency_profile.id == employer_client.active_broker_agency_account.broker_agency_profile.id
                      employer_client.active_broker_agency_account.update_attributes(:is_active => false)
                    end
                  end
                else
                  csv << [
                    "N/A",
                    "N/A",
                    "N/A",
                    person.broker_role.broker_agency_profile.legal_name,
                    person.full_name,
                    person.broker_role.aasm_state
                  ]                  
                end
              else
                csv << [
                  "N/A",
                  "N/A",
                  "N/A",
                  "N/A",
                  person.full_name,
                  person.broker_role.aasm_state
                ]
              end
            end
          end
        rescue
          puts "Bad Broker Record for person_id: #{person.id}" unless Rails.env.test?
        end
      end
    end
  end
end
