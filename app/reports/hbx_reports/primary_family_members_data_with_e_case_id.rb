require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class PrimaryFamilyMembersDataWithECaseId < MongoidMigrationTask
  def migrate
    field_names  = %w(
          Integrated_Case_ID_(e_case_id)
          Subscriber_FN
          Subscriber_LN
          HBX_ID
          SSN
          DOB
          Gender
          Primary_Person_Record_Create_Date
          Type
          Active_Enrollment
          Applied_aptc_amount
          CSR_Enrollment
         )
       count = 0
       file_name = "#{Rails.root}/public/primary_family_members_data_with_e_case_id.csv"
       CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        families = Family.where(:e_case_id.nin => ["", nil])

        families.all.each do |family|
          begin
            person = family.primary_family_member.person
            aptc = 0
            csr = "No"
            if family.has_aptc_hbx_enrollment?
              aptc = family.latest_household.hbx_enrollments.active.order("created_at DESC").first.applied_aptc_amount.to_f
              csr = "Yes" if family.active_household.hbx_enrollments.with_aptc.enrolled_and_renewing.any? {|enrollment| enrollment.plan.is_csr? }
            end

            csv << [
              family.e_case_id,
              person.first_name,
              person.last_name,
              person.hbx_id,
              person.ssn,
              person.dob,
              person.gender,
              person.created_at.to_date,
              "Primary",
              Person.person_has_an_active_enrollment?(person) ? "Yes" : "No",
              aptc,
              csr
             ]

             family.dependents.each do |dependent|
              dependent_person = dependent.person
              csv << [
                family.e_case_id,
                dependent_person.first_name,
                dependent_person.last_name,
                dependent_person.hbx_id,
                dependent_person.ssn,
                dependent_person.dob,
                dependent_person.gender,
                dependent_person.created_at.to_date,
                "Dependent",
                Person.person_has_an_active_enrollment?(dependent_person) ? "Yes" : "No",
                aptc,
                csr
              ]
             end
            count += 1
          rescue
            puts "Bad Family record with id: #{family.id}" unless Rails.env.test?
          end
        end
      end
      puts "Total number of families with e_case_id: #{count}" unless Rails.env.test?
  end
end
