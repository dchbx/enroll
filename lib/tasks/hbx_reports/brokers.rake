require 'csv'

namespace :reports do
  namespace :shop do

    desc "All Brokers"
    task :brokers => :environment do
      include Config::AcaHelper

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
      file_name = fetch_file_format('brokers_list', 'BROKERSLIST')

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        brokers.each do |broker|
          begin
            role = broker.broker_role
            profile = role.broker_agency_profile
            primary_location = profile.primary_office_location
            approved_wfst = role.workflow_state_transitions.detect{ |t| t.to_state == "active"}
            approval_date = approved_wfst.transition_at.strftime("%Y-%m-%d") if approved_wfst
            csv << [
              role.npn,
              profile.legal_name,
              broker.first_name,
              broker.last_name,
              role.email_address,
              role.phone,
              profile.market_kind,
              profile.languages_spoken,
              profile.working_hours,
              profile.accept_new_clients] +

              office_location_info(primary_location) +

              [
                role.created_at.try(:strftime,'%Y-%m-%d'),
                role.aasm_state,
                role.updated_at.try(:strftime,'%Y-%m-%d'),
                approval_date
              ]
            rescue Exception => e
              "Exception on #{broker.hbx_id}: #{e}"
            end
          processed_count += 1
        end
      end

      if Rails.env.production?
        pubber = Publishers::Legacy::ShopBrokersReportPublisher.new
        pubber.publish URI.join("file://", file_name)
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} Brokers to output file: #{file_name}"
    end

    def office_location_info(location)
      return ["","","","",""] if location.blank? || location.address.blank?
      [
        location.address.address_1,
        location.address.address_2,
        location.address.city,
        location.address.state,
        location.address.zip
      ]
    end
  end
end
