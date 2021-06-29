# frozen_string_literal: true

require 'csv'
class CreatingPersonRecord < MongoidMigrationTask

  def migrate
    file_name = ENV['file_name'].to_s
    index = 1
    CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      person = Person.new(first_name: row[0], middle_name: row['Middle name'], last_name: row['Last name'],
                          dob: Date.parse(row['DOB']), ssn: row['SSN'], gender: row['Gender'], hbx_id: row['hbx_id'])
      if person.save
        puts "Person record created for row #{index}." unless Rails.env.test?
      else
        puts person.errors.full_messages
        puts "Person record doesn't created for row #{index}" unless Rails.env.test?
      end
      index += 1
    end
  end
end