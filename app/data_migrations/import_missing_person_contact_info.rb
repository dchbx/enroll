require File.join(Rails.root, "lib/mongoid_migration_task")

class ImportMissingPersonContactInfo < MongoidMigrationTask
  def migrate
    Person.where(employee_roles: {:$exists => true}).where(:$or => [{addresses: {:$exists => false}}, {emails: {:$exists => false}}]).each do |person|
      begin
        ces = person.active_employee_roles.map{|er| er.census_employee }
        if ces.present?
          ces.each do |census_employee|
            if census_employee.address.present?
              person.addresses.create!(census_employee.address.attributes) if person.addresses.blank?
            end
            if census_employee.email.present?
              person.emails.create!(census_employee.email.attributes) if person.emails.blank?
              person.emails.create!(kind: 'work', address: census_employee.email_address) if person.work_email.blank? && census_employee.email_address.present?
            end
          end
        end
      rescue Exception => e
        puts e.message
      end
    end
  end
end
