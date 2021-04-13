require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateOrChangePersonPhoneNumber < MongoidMigrationTask
  def migrate
    begin
      hbx_id = (ENV['hbx_id']).to_s
      kind = (ENV['phone_kind']).to_s
      full_phone_number = (ENV['full_phone_number']).to_s
      country_code = (ENV['country_code']).to_s

      if Person.where(hbx_id: hbx_id).size != 1
         puts "no or more person found with given hbx_id" unless Rails.env.test?
         return
      # Create phone number
      elsif Person.where(hbx_id: hbx_id).first.phones.where(kind:kind).size < 1
        puts "No phone number matching parameters present. Creating new one." unless Rails.env.test?
        person = Person.where(hbx_id: hbx_id).first
        person.phones.create!(country_code: country_code, kind: kind, full_phone_number: full_phone_number)
        puts "The full phone number has been set to: #{full_phone_number} with country code: #{country_code}" unless Rails.env.test?
      end

      # Change phone number 
      if Person.where(hbx_id: hbx_id).first.phones.where(kind: kind).present?
        Person.where(hbx_id: hbx_id).first.phones.where(kind:kind).each do |phone|
          phone.update_attributes(country_code: country_code)
          phone.full_phone_number = (full_phone_number)
          phone.save
          puts "The full phone number has been set to: #{full_phone_number} with country code: #{country_code}" unless Rails.env.test?
        end
      end
    rescue => e
      puts e.message unless Rails.env.test?
    end
  end
end