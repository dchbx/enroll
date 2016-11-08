namespace :migrations do
  desc "Update person's work email by census_employee"
  task :update_person_work_email_by_ce => :environment do
    count = 0
    Person.all_employee_roles.each do |person|
      begin
        next if person.work_email.present?
        ce_email_address = person.employee_roles.last.census_employee.email_address rescue nil
        next if ce_email_address.blank?
        person.add_work_email(ce_email_address)
        person.save
        count += 1
      rescue => e
        puts "Can not migrate work email for person(#{person.full_name}), error: #{e.to_s}"
      end
    end
    puts "Updated work email for #{count} persons."
  end
end
