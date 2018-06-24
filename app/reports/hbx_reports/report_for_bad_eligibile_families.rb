require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class ReportForBadEligibileFamilies < MongoidMigrationTask
  def migrate

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/report_for_bad_eligibile_families.csv"

    field_names  = %w(
          Assistance_applicable_year
          Family_e_case_id
          PrimaryPerson_FN
          PrimaryPerson_LN
          PrimaryPerson_Hbx_ID
          Dependent_FN
          Dependent_LN
          PDC_IA
          PDC_Medicaid
         )

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      Family.all_eligible_for_assistance.each do |family|
        begin
          primary_person = family.primary_applicant.person
          tax_household = family.active_household.latest_active_tax_household
          eligibility_determination = tax_household.latest_eligibility_determination
          members = tax_household.tax_household_members
          #If TaxHousehold is APTC eligible and none of the tax_household_members are IA eligible
          if (eligibility_determination.max_aptc.to_f > 0.0 || eligibility_determination.csr_eligibility_kind != "csr_100")
            if !members.map(&:is_ia_eligible).include?(true)
              members.each do |tax_household_member|
                csv << [
                  tax_household.effective_starting_on.year,
                  family.e_case_id,
                  primary_person.first_name,
                  primary_person.last_name,
                  primary_person.hbx_id,
                  tax_household_member.person.first_name,
                  tax_household_member.person.last_name,
                  tax_household_member.is_ia_eligible,
                  tax_household_member.is_medicaid_chip_eligible
                ]
              end
              puts "Primary_Person_hbx_id: #{primary_person.hbx_id}" unless Rails.env.test?
            end
          else
            members.each do |tax_household_member|
              #If both MedicaidChip and IA are set to true for a tax_household_member
              if tax_household_member.is_ia_eligible && tax_household_member.is_medicaid_chip_eligible
                csv << [
                  tax_household.effective_starting_on.year,
                  family.e_case_id,
                  primary_person.first_name,
                  primary_person.last_name,
                  primary_person.hbx_id,
                  tax_household_member.person.first_name,
                  tax_household_member.last_name,
                  tax_household_member.is_ia_eligible,
                  tax_household_member.is_medicaid_chip_eligible
                ]
                puts "Primary_Person_hbx_id: #{primary_person.hbx_id}" unless Rails.env.test?
              end
            end
          end
        rescue => e
          puts "Bad Family Record, error: #{e}" unless Rails.env.test?
        end
      end
      puts "End of the report" unless Rails.env.test?
    end
  end
end
