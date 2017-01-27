require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class TerminatedHbxEnrollments < MongoidMigrationTask
  def migrate
    families = get_families
        field_names  = %w(
                   Enrolled_Member_HBX_ID
                   Enrolled_Member_First_Name
                   Enrolled_Member_Last_Name
                   Employer_Legal_Name
                   Employer_Fein
                   Employee_Census_State
                   Primary_Member_HBX_ID
                   Primary_Member_First_Name
                   Primary_Member_Last_Name
                   Market_Kind
                   Carrier_Legal_Name
                   Plan_Name
                   Coverage_Type
                   HIOS_ID
                   Policy_ID
                   Enrollment_State
                   Effective_Start_Date
                   Coverage_End_Date
                   Member_relationship
                   Coverage_state_occured)

        processed_count = 0
        Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
        file_name = "#{Rails.root}/hbx_report/edi_enrollment_termination_report.csv"

        CSV.open(file_name, "w", force_quotes: true) do |csv|
          csv << field_names
          families.each do |family|
            if family.try(:primary_family_member).try(:person).try(:active_employee_roles).try(:any?) || family.try(:primary_family_member).try(:person).try(:consumer_role).try(:present?)
              hbx_enrollments = family.active_household.hbx_enrollments.select{|enrollment| enrollment_for_report?(enrollment) }
              hbx_enrollment_members = hbx_enrollments.flat_map(&:hbx_enrollment_members)
              hbx_enrollment_members.each do |hbx_enrollment_member|
                if hbx_enrollment_member
                  person = hbx_enrollment_member.person
                  enrollment = hbx_enrollment_member.hbx_enrollment
                  primary_person = family.primary_family_member.person
                  employer = enrollment.try(:employer_profile)
                  census_employee = person.try(:employee_roles).try(:first).try(:census_employee)
                  csv << [
                      person.hbx_id,
                      person.first_name,
                      person.last_name,
                      employer ? employer.legal_name : "IVL",
                      employer ? employer.fein : "IVL",
                      census_employee ? census_employee.aasm_state : "IVL",
                      primary_person.hbx_id,
                      primary_person.first_name,
                      primary_person.last_name,
                      enrollment.kind,
                      enrollment.plan.carrier_profile.legal_name,
                      enrollment.plan.name,
                      enrollment.coverage_kind,
                      enrollment.plan.hios_id,
                      enrollment.hbx_id,
                      enrollment.aasm_state,
                      enrollment.effective_on,
                      enrollment.terminated_on,
                      primary_person.find_relationship_with(person),
                      transition_date(enrollment)
                  ]
                end
                processed_count += 1
              end
            end
          end
          puts "For date #{date_of_termination}, total terminated hbx_enrollments count #{processed_count} and output file is: #{file_name}" unless Rails.env.test?
        end
  end

  def get_families
    Family.where(:"households.hbx_enrollments" =>
                     {:$elemMatch =>
                          {'$or'=>
                               [{:"aasm_state" => "coverage_terminated"},
                                {:"aasm_state" => "coverage_termination_pending"}],
                           "workflow_state_transitions.transition_at" => date_of_termination}})
  end

  def date_of_termination
    start_date = ENV['start_date'] ? Date.strptime(ENV['start_date'], '%Y-%m-%d').beginning_of_day : Date.yesterday.beginning_of_day
    end_date = ENV['end_date'] ? Date.strptime(ENV['end_date'], '%Y-%m-%d').end_of_day : Date.yesterday.end_of_day
    start_date..end_date
  end

  def enrollment_for_report?(enrollment)
    enrollment_state?(enrollment) && enrollment_date?(enrollment)
  end

  def enrollment_state?(enrollment)
    enrollment.coverage_terminated? || enrollment.coverage_termination_pending?
  end

  def enrollment_date?(enrollment)
    (date_of_termination).cover?(transition_date(enrollment).try(:strftime, '%Y-%m-%d'))
  end

  def transition_date(enrollment)
    enrollment.workflow_state_transitions.try(:first).try(:transition_at)
  end
end
