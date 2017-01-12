require 'csv'

PATH = Rails.root.join "list_of_all_assisters_and_cac.csv"
cr = Person.where("csr_role" => {'$exists'=> true})
ar = Person.where("assister_role" => {'$exists'=> true})

CSV.open(PATH, "wb") do |csv|
  headers = %w(First_Name Last_Name Email Role)
  csv << headers
  ar.each do |role|
      assister_role = [role.first_name, role.last_name, role.work_email_or_best, 'Assister']
      csv.add_row assister_role
  end
  
  cr.each do |person|
      csr_role = [person.first_name, person.last_name, person.work_email_or_best, 'CAC']
      csv.add_row csr_role
  end
  puts "Output written to #{PATH}"
end
