require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateOrChangePersonAddress < MongoidMigrationTask
  def migrate
    begin
      hbx_id = (ENV['hbx_id']).to_s
      kind = (ENV['address_kind']).to_s
      address_1 = (ENV['address_1']).to_s
      city = (ENV['city']).to_s
      zip = (ENV['zip']).to_s
      state_code = (ENV['state_code']).to_s

      person = Person.where(hbx_id: hbx_id).first

      if person.nil?
         puts "no or more person found with given hbx_id" unless Rails.env.test?
         return
      end

      # State is not validated in address model, but if its present, we should assure it is submitted as abbreviation
      if state_code.present? && state_code.length > 2
        puts "States should be submitted with their abbreviation format, I.E. 'MD' instead of 'Maryland'." unless Rails.env.test?
        return
      end

      # Kind is a required attribute in the address model
      if kind.nil? || %w(home work mailing).exclude?(kind)
        puts "Please include a kind of 'home', 'work', or 'mailing.'" unless Rails.env.test?
        return
      end

      if zip.nil?
        puts "Please include a zip in the form: 12345 or 12345-1234" unless Rails.env.test?
        return
      end

      address = person.addresses.where(kind: kind).first
      # Modify address
      if address.present?
        address.update_attributes!(kind: kind, address_1: address_1, city: city, state: state_code, zip: zip)
        person.save!
        puts "The address has been set to: #{address_1}, #{city}, #{zip}." unless Rails.env.test?
      else # Create New Address
        puts "No address matching parameters present. Creating new one." unless Rails.env.test?
        address = person.addresses.build(kind: kind, address_1: address_1, city: city, zip: zip, state: state_code)
        address.save!
        person.save!
        puts "The address has been set to: #{address_1}, #{city}, #{zip}." unless Rails.env.test?
      end
    rescue => e
      puts e.message unless Rails.env.test?
    end
  end
end 
