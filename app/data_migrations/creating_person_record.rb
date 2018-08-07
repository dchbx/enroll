require 'csv'
class CreatingPersonRecord < MongoidMigrationTask

  def migrate
    file_name = ENV['file_name'].to_s
    index = 1
    CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      begin
        person = Person.where(ssn: row['SSN']).first_or_create(first_name: row[0], middle_name: row['Middle name'], last_name: row['Last name'],
                            dob: Date.parse(row['DOB']), gender: row['Gender'], hbx_id: row['hbx_id'])
      

        address = Address.new(address_1: row['address 1'], address_2: row['address 2'], city: row['city'], state: row['state'], zip: row['zip'], kind: "home")
        
        person.addresses << address
        puts "Person record created for row #{index}." unless Rails.env.test?
      rescue Exception => e
        puts e
      end
      index += 1
    end
  end
end