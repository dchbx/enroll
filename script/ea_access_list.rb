  require 'csv'
  
  batch_size = 500
  offset = 0
  user_count = User.count

  file_name = "#{Rails.root}/ea_access_list_#{DateTime.now.strftime("%m_%d_%Y_%H_%M")}.csv"

  processed_count = 0
  
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << ["User Id", "User's Name", "OIM ID", "Email" ,"Roles", "Created Date", "Last Login Date", "Start on(ER-EE/ER-BA)", "Termination Date(ER-EE/ER-BA)"]
    while offset < user_count
      User.offset(offset).limit(batch_size).each do |user|
        if processed_count % 1000 == 0
          puts "processed #{processed_count}" unless Rails.env.test?
        end
        begin
          person = user.person
          if person.nil?
            csv << ["No person record found", "No person record", user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at]
          elsif person.has_active_employer_staff_role?
            employer_profile_id = person.employer_staff_roles.first.employer_profile_id
            employer_profile = EmployerProfile.find(employer_profile_id)
            employer_profile.broker_agency_accounts.unscoped.all.each do |baa|
              next if baa.nil? || baa.broker_agency_profile.nil? || baa.broker_agency_profile.market_kind == "individual"
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at, baa.start_on, baa.end_on]
            end
          elsif person.employee_roles?
            person.employee_roles.each do |emp|
              ce = emp.census_employee
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at, ce.hired_on, ce.employment_terminated_on]
            end
          elsif person.hbx_staff_role?
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, person.hbx_staff_role.subrole, user.created_at, user.last_sign_in_at ]
          else
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at, ]
          end
        rescue Exception => e
          puts "Errors #{e} #{e.backtrace}"
        end
        processed_count += 1
      end
      offset = offset + batch_size
    end
    puts "#{processed_count} users to output file: #{file_name}" unless Rails.env.test?
  end