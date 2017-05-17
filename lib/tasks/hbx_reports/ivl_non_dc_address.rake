# Monthly Report: Rake task to find IVL cases with active coverage with non-DC addresses
# Run this task every Month: RAILS_ENV=production bundle exec rake reports:ivl:ivl_non_dc_address

require 'csv'
 
namespace :reports do
  namespace :ivl do

    desc "Monthly report of IVL cases with non-DC addresses"
    task :ivl_non_dc_address, [:file] => :environment do

      field_names  = %w(
        HBX_ID
        First_Name
        Last_Name
        Date_Of_Birth
        SSN
        Address_line_1
        Address_line_2
        City
        State
        Zipcode
        No_dc_address_reason 
        Consumer_role 
        Employee_role
      )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/ivl_non_dc_address.csv"
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

        Person.all.each do |person|
          begin
            if person.has_active_consumer_role? && person.home_address.try(:state) != 'DC'
              if person.primary_family.present? && person.primary_family.households.flat_map(&:hbx_enrollments).detect { |enr| enr.kind == "individual" && HbxEnrollment::ENROLLED_STATUSES.include?(enr.aasm_state)}
                csv << [person.hbx_id, 
                        person.first_name, 
                        person.last_name,
                        person.dob,
                        person.ssn,
                        person.home_address.try(:address_1),
                        person.home_address.try(:address_2),
                        person.home_address.try(:city),
                        person.home_address.try(:state),
                        person.home_address.try(:zip),
                        person.no_dc_address_reason, 
                        person.consumer_role.present?, 
                        person.employee_roles.present?
                       ]
                processed_count +=1
              end
            end
          rescue Exception => e
            puts e.message
          end
        end

        puts "File path: %s. Total count of IVL cases with non DC address: %d." %[file_path, processed_count]
      end
    end
  end
end