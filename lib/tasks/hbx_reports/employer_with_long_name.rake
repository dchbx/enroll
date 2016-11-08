require 'csv'

namespace :reports do
  namespace :shop do
    desc "Employer's with name over 60 characters"
    task :employer_long_name_list => :environment do
      # collecting all the employers list and comparing with glue DB
      organizations = Organization.where(:'employer_profile'.exists=>true)

      field_names  = %w(
          employer_legal_name
          fein
          dba
          hbx_id
          conversion(true/false)
        )
      processed_count = 0
      file_name = "#{Rails.root}/public/employer_with_name_over_sixty_character_list.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |o|
          e=o.employer_profile
          if (!e.legal_name.blank? && e.legal_name.length>=60)||(!e.dba.blank? && e.dba.length>=60)
            if o.employer_profile.profile_source.downcase == 'conversion'
              conversion=true
            else
              conversion=false
            end
          csv << [
              o.legal_name,
              o.fein,
              o.dba,
              o.hbx_id,
              conversion
          ]
          end
        end
        processed_count += 1
      end
      puts "List of all the employers with legal name or dob more than 60 characters #{file_name}"
    end
  end
end