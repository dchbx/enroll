require "csv"
include VerificationHelper

namespace :reports do

  desc "outstanding_dc_residency_report"
  task :outstanding_dc_residency_report => :environment do

    field_names  = %w(
          HBX_ID
          First_Name
          Last_Name
          DUE_DATE
    )

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/outstanding_dc_residency_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      ver_type = "DC Residency"
      batch_size = 1000
      offset = 0
      person_count =  Person.all_consumer_roles.count

      while offset <= person_count
        Person.all_consumer_roles.offset(offset).limit(batch_size).each do |person|
          begin
            family = person.primary_family rescue nil
            next if family.blank?
            family.family_members.active.each do |family_member|
              person = family_member.person rescue nil
              next if person.blank? || person.consumer_role.blank? || person.verification_types.select {|v_type| v_type == ver_type}.blank? || person.consumer_role.vlp_authority == "curam" || !type_unverified?(ver_type, person)
              due_date = family.min_verification_due_date || TimeKeeper.date_of_record + 95.days
              csv << [
                person.hbx_id,
                person.first_name,
                person.last_name,
                due_date
              ]
            end
          rescue => e
            puts "Errors #{e} #{e.backtrace}"
          end
        end
        offset = offset + batch_size
      end
    end
    puts "Generated Outstanding DC Residency Report"
  end
end
