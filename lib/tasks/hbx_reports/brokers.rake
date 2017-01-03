require 'csv'

namespace :reports do
  namespace :shop do

    desc "All Brokers"
    task :brokers => :environment do

      date_range = Date.new(2015,10,1)..TimeKeeper.date_of_record
      brokers = Person.exists(broker_role: true).broker_role_having_agency
      field_names  = %w(
          NPN
          Broker_Agency
          First_Name
          Last_Name
          Email
          Phone
          Market_kind
          Languages_spoken
          Evening/Weekend_hours
          Accept_new_clients
          Address_1
          Address_2
          City
          State
          Zip
          Application_Created_On
          Broker_Status
          Last_Status_Updated_On
          Approval_date
        )

      processed_count = 0
      file_name = "#{Rails.root}/brokers_list_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        brokers.each do |broker|  
            csv << [
            broker.broker_role.npn,
            broker.broker_role.broker_agency_profile.try(:legal_name),
            broker.first_name,
            broker.last_name, 
            broker.broker_role.email_address, 
            broker.broker_role.phone,
            broker.broker_role.broker_agency_profile.try(:market_kind),
            broker.broker_role.broker_agency_profile.try(:languages_spoken),
            broker.broker_role.broker_agency_profile.try(:working_hours),
            broker.broker_role.broker_agency_profile.try(:accept_new_clients)] +

            organization_info(broker) +

            [
              broker.broker_role.created_at.try(:strftime,'%Y-%m-%d'),
              broker.broker_role.aasm_state,
              broker.broker_role.updated_at.try(:strftime,'%Y-%m-%d'),
              broker.broker_role.workflow_state_transitions.detect{ |t| t.to_state == "active"}.try(:transition_at).try(:strftime,'%Y-%m-%d'),

            ]
           processed_count += 1
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} Brokers to output file: #{file_name}"
    end

    def organization_info(broker)
      return ["","","","",""] if broker.broker_role.broker_agency_profile.nil?
      [
        broker.broker_role.broker_agency_profile.organization.primary_office_location.address.address_1,
        broker.broker_role.broker_agency_profile.organization.primary_office_location.address.address_2,
        broker.broker_role.broker_agency_profile.organization.primary_office_location.address.city,
        broker.broker_role.broker_agency_profile.organization.primary_office_location.address.state,
        broker.broker_role.broker_agency_profile.organization.primary_office_location.address.zip
      ]
    end
  end
end