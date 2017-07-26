#this rake task a reports with
#1)phone number that have full_phone_numbers of exactly 11 digits
#2)phone number that have full_phone_numbers of less than 10 digits
require 'csv'

namespace :reports do
  namespace :shop do
    desc "report of bad phone numbers"
    task :generate_report_of_bad_phone_number => :environment do

      organizations = Organization.where(:"office_locations.phone.full_phone_number"=> { "$exists" => true })
      people = Person.where(:"phones.full_phone_number"=> { "$exists" => true })

      field_names  = %w(person_or_organization
                        hbx_id
                        full_phone_number
                        full_phone_number_length
                        country_code
                        extension
                        area_code
                        number
                      )
      processed_count = 0
      file_name = "#{Rails.root}/public/report_of_bad_phone_number.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |organization|
          next unless organization.office_locations
          organization.office_locations.each do |office_location|
            next unless office_location.phone
              phone = office_location.phone
              next unless phone.full_phone_number
              length = phone.full_phone_number.length
              next unless length < 10 || length == 11
              csv << ["organization",
                      organization.hbx_id,
                      phone.full_phone_number,
                      phone.full_phone_number.size,
                      phone.country_code,
                      phone.extension,
                      phone.area_code,
                      phone.number
                      ]
              processed_count += 1
          end
        end

        people.each do |person|
          next unless person.phones
            person.phones.each do |phone|
              next unless phone.full_phone_number
              length = phone.full_phone_number.length
              next unless length < 10 || length == 11
              csv << ["individual",
                      person.hbx_id,
                      phone.full_phone_number,
                      phone.full_phone_number.size,
                      phone.country_code,
                      phone.extension,
                      phone.area_code,
                      phone.number
                     ]
              processed_count += 1
            end
        end
      end
      puts "List of #{processed_count} bad phone numbers #{file_name}"
    end
  end
end