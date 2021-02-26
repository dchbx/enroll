# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# Census Employee termination Code
class BulkCensusEmployeesTermination < MongoidMigrationTask
  def migrate
    files = Dir.glob(File.join(Rails.root, "bulk_terminate", "*.xlsx"))
    organization = BenefitSponsors::Organizations::Organization.where(fein: ENV['fein']).first
    all_census_employees = CensusEmployee.by_benefit_sponsor_employer_profile_id(organization.employer_profile.id)
    files.each do |file_path|
      result = Roo::Spreadsheet.open(file_path)
      sheets = result.sheets
      sheets.each do |sheet_name|
        sheet_data = result.sheet(sheet_name)
        @header_row = sheet_data.row(1)
        assign_headers
        last_row = sheet_data.last_row

        (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
          row_info = sheet_data.row(row_number)
          key = row_info[@headers["ssn"]].squish
          key = key.gsub('-','')
          first_name = row_info[@headers["first_name"]].squish
          last_name = row_info[@headers["last_name"]].squish
          termination_date = row_info[@headers["termination_date"]].to_s.squish
          termination_date = Date.strptime(termination_date,'%m/%d/%y').to_date
          census_employees = all_census_employees.by_ssn(key)
          if census_employees.size > 1
            puts "#{first_name} #{last_name} has multiple census employees #{census_employees.size}"
          else
            census_employee = census_employees.first
            if census_employee.present?
              BulkCensusEmployeesTerminationJob.perform_now(census_employee, termination_date)
            else
              puts "unable to find census employee: #{first_name} #{last_name}"
            end
          end
        end
      end
    end
  end

  def assign_headers
    @headers = {}
    @header_row.each_with_index { |header,i| @headers[header.to_s.underscore.strip] = i }
    @headers
  end
end
