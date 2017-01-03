# This is rake task used to generate a report of census employees linked with employers and have no address in roaster.
# To run rake task: RAILS_ENV=production rake reports:shop:employee_with_no_address_list

require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee with no address account information"
    task :employee_with_no_address_list => :environment do
      census_members = CensusMember.where(:aasm_state.in => CensusEmployee::LINKED_STATES, :'address'.exists => false)
      field_names= %w(
                      primary_subscriber_hbx_id
                      first_name
                      last_name
                      er_legal_name
                      fein
                    )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/employee_with_no_address_list.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        total_records = census_members.count()
        offset =0
        step=100
        while offset <= total_records do
          if offset+step<=total_records
            census_members= census_members.limit(step).offset(offset)
          else
            census_members= census_members.limit(step).offset(total_records)
          end
          census_members.each do |census_member|
                csv << [
                    census_member.try(:employee_role).try(:person).try(:hbx_id),
                    census_member.try(:employee_role).try(:person).try(:first_name),
                    census_member.try(:employee_role).try(:person).try(:last_name),
                    census_member.try(:employer_profile).try(:legal_name),
                    census_member.try(:employer_profile).try(:fein)
                ]
                processed_count += 1
          end
          offset=offset+step
        end
      end
      puts "The report has been generated as #{file_name}" unless Rails.env.test?
      end
    end
end