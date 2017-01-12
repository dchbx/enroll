# Finds people who have vlp documents matching Afghanistan in country of citizenship or issuing country. 

country_of_citizenship_people = Person.where("consumer_role.vlp_documents.country_of_citizenship" => "Afghanistan")

issuing_country_people = Person.where("consumer_role.vlp_documents.issuing_country" => "Afghanistan")

all_afghanistan_people = (country_of_citizenship_people + issuing_country_people).uniq

CSV.open("afghanistan_people.csv","w") do |csv|
  csv << ["First Name","Last Name","DOB","Phone Number","Email Address"]
  all_afghanistan_people.each do |person|
    phone = person.phones.map(&:full_phone_number).uniq.join(",")
    email = person.emails.map(&:address)
    unless person.user.blank?
      email = (email + [person.user.email]).uniq
    end
    email = email.join(",")
    csv << [person.first_name, person.last_name, person.dob,phone,email]
  end
end