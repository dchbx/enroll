
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveEmployerStaffRoleFromPerson< MongoidMigrationTask
  def migrate
    begin
      #person_hbx_id=112777622 employer_staff_role_id="123123123123"
      hbx_id = ENV['person_hbx_id']
      employer_staff_role_id = ENV['employer_staff_role_id']
      person = Person.where(hbx_id:hbx_id).first
      if person.nil?
        puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
      elsif person.employer_staff_roles.size < 1
        puts  "No employer staff roles found for person with given hbx_id: #{hbx_id}" unless Rails.env.test?
      else
        (0..person.employer_staff_roles.size-1).each do |i|
          if person.employer_staff_roles[i].id.to_s == employer_staff_role_id
            person.employer_staff_roles[i].close_role
            person.employer_staff_roles[i].update_attributes(is_active:false)
            puts  "The target employer staff role of person with given hbx_id: #{hbx_id} has been closed" unless Rails.env.test?
            break
          end
        end
      end
    rescue => e
      puts "#{e}"
    end
  end
end