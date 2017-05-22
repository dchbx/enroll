require 'csv'
namespace :reports do
  namespace :shop do
    desc "Name list of employers with long phone extension"
    task :employer_with_long_phone_extension_list => :environment do
      organizations=Organization.where(:'employer_profile'.exists=>true)
      field_names  = %w(
          First_Name
          Last_Name
          ER_FEIN
          Phone_Number
          Phone_Extension
          HBX_ID
        )
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/Name_list_of_employers_with_long_phone_extension.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |organization|
           people=Person.staff_for_employer_including_pending(organization.employer_profile)
           if people!=nil
             people.each do |person|
               if person.phones? && person.phones.first.extension?&&person.phones.first.extension.size>4
                 person.phones.each do |phone|
                       csv << [
                               person.first_name,
                               person.last_name,
                               organization.employer_profile.fein,
                               phone.number,
                               phone.extension,
                               person.hbx_id
                              ]
                  end
               end
             end
           end
        end
        puts "List of all the employers with longer phone extension#{file_name}"
       end
    end
   end
  end