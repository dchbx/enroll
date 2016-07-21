# Fixing curam users, moving to verified
def get_people
  Person.where('consumer_role' => {'$exists' => true},
               'consumer_role.lawful_presence_determination.vlp_authority' => 'curam')
end

def update_person(person)
  begin
    person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
    person.consumer_role.import!
    person.save!
    print "."
  rescue => e
    puts "Error for Person id: #{person.id}. Error: #{e.message}"
  end
end

def fix_curam!
  people_to_fix = get_people
  puts "#{people_to_fix.count} will be fixed."
  people_to_fix.each do |person|
    update_person(person)
  end
end

fix_curam!