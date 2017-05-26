#this rake task produces an csv report providing all brokers that have had a claim URL sent to them upon Admin Approval
require 'csv'

namespace :reports do
  namespace :shop do
    desc "All Brokers have had a claim URL sent to them upon Admin Approval"
    task :brokers_with_URL_from_admin_approval => :environment do
      invitations=Invitation.where(role:"broker_role").all
      field_names  = %w(
          Broker_Agency_Legal_Name
          First_Name
          Last_Name
          Email
          NPN
          Date_of_Unique_URL_being_sent
          Unique_URL
        )
      processed_count = 0
      file_name = "#{Rails.root}/brokers_list_with_URL_from_admin_approval.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        invitations.each do |invitation|
          unless BrokerRole.find(invitation.source_id).nil?
            broker=BrokerRole.find(invitation.source_id)
            unless broker.nil?
              csv << [
                broker.broker_agency_profile.try(:legal_name),
                broker.person.first_name,
                broker.person.last_name,
                broker.email_address,
                broker.npn,
                invitation.created_at,
                "http://enroll.dchealthlink.com/invitations/#{invitation.id}/claim"
              ]
              processed_count += 1
              end
          end
        end
      end
      puts "#{processed_count} Brokers to output file: #{file_name}"
    end
  end
end