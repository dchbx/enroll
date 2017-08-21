require File.join(Rails.root, "lib/mongoid_migration_task")

class EeWithoutEmployeeRole< MongoidMigrationTask
	def migrate
		ee_count = 0
		Person.all.each do |person|
			begin
				if person.employee_roles.present?
					person.employee_roles.each do |employee_role|
						if employee_role.census_employee.present? && employee_role.census_employee.employee_role.blank?
							rehired_employee = person.employee_roles.where(:employer_profile_id => employee_role.employer_profile_id, :_id.ne => employee_role.id).detect{|role| role.census_employee.rehired?}
							next if rehired_employee.blank?
							census_employee = employee_role.census_employee
							census_employee.employee_role_id = employee_role.id
							census_employee.save!
							ee_count += 1
							puts "employee_role_id: #{employee_role.id} assigned for census_employee with id: #{employee_role.census_employee.id} of person hbx_id: #{person.hbx_id}" unless Rails.env.test?
						end
					end
				end
			rescue Exception => e
				puts e.message
			end
		end
		puts "No. of census_employee's assigned employee_role: #{ee_count}" unless Rails.env.test?
	end
end
