require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateFullPhoneNumber < MongoidMigrationTask

  #collect phones of a person for which full phone number is nil
  def get_person_phones
    Person.where(:'phones'.exists=>true).where(:"phones.full_phone_number".exists => false).map(&:phones).flatten.compact
  end

  # collect phone of office location for which full phone number is nil
  def get_office_phones
    Organization.where(:'office_locations.phone'.exists=>true).where(:"office_locations.phone.full_phone_number".exists =>false).
        map(&:office_locations).flatten.map(&:phone).flatten.compact
  end

  def migrate
    person_phones = get_person_phones
    office_phones = get_office_phones
    count = 0
    phones = person_phones + office_phones
    phones.each do |phone|
      phone.set(full_phone_number: phone.to_s)
      count += 1
    end
    # puts "updated #{person_phones.count} full phone number for persons"
    # puts "updated #{office_phones.count} full phone number for office locations"
  end
end
