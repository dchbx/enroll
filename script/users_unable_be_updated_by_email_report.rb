require 'csv'
csv_file_path = "script/user_email_list.csv"
out_file_path = "script/user_email_lookup_results.csv"
user_not_exists_count=0
person_not_linked_count=0
CSV.open(out_file_path, 'w') do |csv|
  csv << ["username", "email", "user exists?", "person linked?"]
CSV.foreach(csv_file_path, headers: true) do |row|
  username = row[0]
  email=row[1]
  out_row=[row[0],row[1],"Not Exists","Not Linked"]
  if User.where(email:email).first.present?
    user = User.where(email:email).first
    if user.oim_id== username
      out_row[2]<< "Matched"
    else
      out_row[2]<< "Not Matched"+user.oim_id
    end
    if user.person.present?
      out_row[3]<<"Linked"
    else
      person_not_linked_count=person_not_linked_count+1
    end
  else
    user_not_exists_count=user_not_exists_count+1
    person_not_linked_count=person_not_linked_count+1
  end
  csv << out_row
end
end
puts  "total count of emails with no Users: #{user_not_exists_count}"
puts  "total count of emails with no Person linkeds: #{person_not_linked_count}"
