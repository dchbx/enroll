require 'csv'

namespace :reports do
  namespace :shop do

    desc "Report of all people records associated with email address ending in @advita.com"
    task :people_with_email_advita_list => :environment do
      people=Person.where(:'emails.address'=>/@advita.com$/i)
      #people=Person.where(:'emails.address'=>/@/i)
      field_names  = %w(
          hbx_id
          first_name
          last_name
          email
          phone
          created_at(date/time)
        )
      processed_count = 0
      file_name = "#{Rails.root}/people_with_email_advita_list.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        people.each do |p|

          csv << [
              p.hbx_id,
              p.first_name,
              p.last_name,
              p.try(:emails).try(:address),
              p.try(:phones).try(:full_phone_number),
              p.created_at
          ]
        end
        processed_count += 1
      end
      puts "Report of all people records associated with email address ending in @advita.com  #{file_name}"
    end
  end
end