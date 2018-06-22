require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeDateOfHire < MongoidMigrationTask
  def migrate
    begin
      ENV['hbx_id'].split(",").each do |hbx_id|
        person=Person.where(hbx_id: hbx_id).first
        doh = Date.strptime(ENV['new_doh'].to_s, "%m/%d/%Y")
        employer_profile = EmployerProfile.find(ENV['employer_profile_id'])
        if person.nil? || employer_profile.nil?
          puts "No Person / Employer was found with the given id #{hbx_id}" unless Rails.env.test?
        else
          employee_role = person.employee_roles.where(:employer_profile_id => employer_profile.id).first
          if employee_role.present?
            employee_role.update_attributes(:hired_on => doh)
            puts "Changed employee role new doh to #{doh}" unless Rails.env.test?
          else
            puts "No Employee role found" unless Rails.env.test?
          end
        end
      end
    rescue Exception => e
      puts e.message
    end
  end
end
