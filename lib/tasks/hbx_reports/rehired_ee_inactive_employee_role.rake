# Report: Rake task to Identify ReHired EE's with Inactive Employee_Role
# RAILS_ENV=production bundle exec rake reports:shop:rehired_ee_inactive_employee_role

require 'csv'

namespace :reports do
  namespace :shop do

    desc "Query To Identify ReHired EE's with Inactive Employee_Role"
    task :rehired_ee_inactive_employee_role, [:file] => :environment do

      field_names  = %w(hbx_id full_name employer fein)
      total_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/rehired_ee_inactive_employee_role.csv"
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

        # get the persons that have more than one employee_role
        person_ids =  Person.collection.aggregate([
                        {"$unwind" => "$employee_roles"},
                        {'$group' => {
                          '_id' => '$_id',
                          'count' => {'$sum' => 1},
                          'name' => {'$addToSet' => '$employee_roles._id'}}
                        },
                        {'$match' => {'count' => {'$gt' => 1 }}}
                      ]).map{|a| a["_id"]}

        Person.where(:id.in => person_ids).each do |person|
          begin
          latest_employee_role = person.employee_roles[-1]
          first_employee_role = person.employee_roles[0]
          if (latest_employee_role.census_employee.employer_profile.id ==  first_employee_role.census_employee.employer_profile.id)
            legal_name = latest_employee_role.census_employee.employer_profile.organization.legal_name
            fein = latest_employee_role.census_employee.employer_profile.organization.fein
            if (["eligible","employee_role_linked"].include?(latest_employee_role.census_employee.aasm_state) &&
                latest_employee_role.census_employee.employee_role_id == nil &&
                first_employee_role.census_employee.aasm_state == 'rehired')
              csv << [person.hbx_id, person.full_name, legal_name, fein]
              total_count += 1
            end
          end
          rescue Exception => e
            puts "***bad record*** #{person.hbx_id}, #{person.full_name}, #{legal_name}, #{fein}"
          end
        end
        puts "File path: %s. Total count of rehired EE's with inactive employee_roles: %d." %[file_path, total_count]
      end
    end
  end
end
