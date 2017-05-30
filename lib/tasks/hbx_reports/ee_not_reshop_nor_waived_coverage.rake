#this monthly run rake task is to generate a report to identify EEs that did not reshop and/or elected to waive coverage.

require 'csv'

namespace :reports do
  namespace :census_employee do

    desc "List of employees that did not reshop and/or elected to waive coverage "
    task :employee_not_reshop_nor_waive_coverage => :environment do
      month=TimeKeeper.date_of_record.month+1
      year=TimeKeeper.date_of_record.year


      date_of_termination=Date.yesterday.beginning_of_day..Date.yesterday.end_of_day
      # find families who terminated their hbx_enrollments
      families = Family.where(:"households.hbx_enrollments" =>{ :$elemMatch => {:"aasm_state" => "coverage_terminated",
                                                                                :"termination_submitted_on" => date_of_termination}})
      field_names  = %w(
               Group
               Next_plan_year_start_date
               Next_plan_year_end_date
               Prior_plan_year_start_date
               Prior_plan_year_end_date
               ee_first_name
               ee_last_name
               Hbx_id_of_employee

             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/ee_not_reshop_nor_waive_coverage.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        families.each do |family|
          if family.primary_family_member.person.active_employee_roles.present?
            # find hbx_enrollments who's aasm state=coverage_terminated and termination_submitted_on == yesterday day
            hbx_enrollments = [family].flat_map(&:households).flat_map(&:hbx_enrollments).select{|hbx| hbx.aasm_state == "coverage_terminated" && hbx.kind == "employer_sponsored" && hbx.termination_submitted_on.try(:strftime, '%Y-%m-%d') == Date.yesterday.strftime('%Y-%m-%d')}
            hbx_enrollment_members = hbx_enrollments.flat_map(&:hbx_enrollment_members)
            hbx_enrollment_members.each do |hbx_enrollment_member|
              if hbx_enrollment_member
                csv << [
                    hbx_enrollment_member.person.hbx_id,
                    hbx_enrollment_member.person.first_name,
                    hbx_enrollment_member.person.last_name,
                    family.primary_family_member.person.active_employee_roles.first.employer_profile.legal_name,
                    family.primary_family_member.person.active_employee_roles.first.employer_profile.fein,
                    family.primary_family_member.person.hbx_id,

                ]
              end
              processed_count += 1
            end
          end
        end
        puts "For month #{date_of_termination}, total employee not reshop and/or elected to waive coverage count #{processed_count} and information output file: #{file_name}"
      end
    end
  end
end