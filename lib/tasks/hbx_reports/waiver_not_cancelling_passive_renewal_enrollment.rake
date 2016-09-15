# Waiver Report for 9/1 Employees who had passive renewal enrollments in auto-renewing state and also had renewed wavied enrollment
# To run rake: RAILS_ENV=production bundle exec rake reports:shop:waiver_not_cancelling_passive_renewals
require 'csv'

namespace :reports do
  namespace :shop do

    desc "List of EEs in with waived coverage state on ER roster, but has an active 7/1 renewal policy in EE account"
    task :waiver_not_cancelling_passive_renewals => :environment do
      count = 0
      renewal_policy_date = Date.new(2016,9,1)
      # All Renewing Employers - Includes Conversion Employers too.
      all_renewing_employers = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_policy_date, :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE}})

      field_names  = %w(
                        Employer_Name
                        Employer_Fein
                        Employee_First_Name
                        Employee_Last_Name
                        Employee_HBX_ID
                        SSN
                        DOB
                        Coverage_kind
                        ER_Sponsored_Passive_Enrollment_ID
                        Passive_Enrollment_Created_At
                        Enrollment_Waived_Time_Stamp
                        )

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/waiver_not_cancelling_passive_renewal_enrollment.csv"

      CSV.open(file_name, "w") do |csv|
        csv << field_names

        all_renewing_employers.each do |employer|
          census_employees = employer.employer_profile.census_employees
          
          census_employees.each do |ce|
            renewing_enrollments = ce.try(:renewal_benefit_group_assignment).try(:hbx_enrollments)

            next if renewing_enrollments.blank?
            # enrollment wavied in open ernrollment period
            ['health','dental'].each do |ct|
              renewing_enrollment_waived = renewing_enrollments.select{ |hbx|
                (HbxEnrollment::WAIVED_STATUSES).include?(hbx.aasm_state) &&
                    (hbx.benefit_group.plan_year.open_enrollment_start_on..hbx.benefit_group.plan_year.open_enrollment_end_on).cover?(hbx.submitted_at) && hbx.coverage_kind==ct}
              # employer sponsored renewing_enrollment
              renewing_enrollment_auto_renewing = renewing_enrollments.select{ |hbx|
                (HbxEnrollment::RENEWAL_STATUSES).include?(hbx.aasm_state) && hbx.coverage_kind==ct }

              # If there are renewing enrollments with both [ Waived(inactive) and Renewing ] statuses from same coverage kind =health/dental for an employee, we want to report them
              if renewing_enrollment_auto_renewing.present? && renewing_enrollment_waived.present?


                csv << [
                    ce.employer_profile.organization.legal_name,
                    ce.employer_profile.fein,
                    ce.first_name,
                    ce.last_name,
                    ce.employee_role.person.hbx_id,
                    ce.ssn,
                    ce.dob,
                    renewing_enrollment_auto_renewing.first.coverage_kind,
                    renewing_enrollment_auto_renewing.first.hbx_id,
                    renewing_enrollment_auto_renewing.first.created_at,
                    renewing_enrollment_waived.first.submitted_at
                ]
                count += 1
              end
            end
          end
        end
        puts "Waiver Report for 9/1 Employees Generated on #{Date.today}, Total 9/1 Employees count #{count} and Employees information output file: #{file_name}"
      end # CSV close
    end

  end
end