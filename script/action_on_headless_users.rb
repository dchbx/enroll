require 'csv'

def action(user, person_email, duplicate)

  if user.size == 1
    user = user.first
    case duplicate
    when "remove"
      user.destroy!
    when "change"
      user.update_attributes(email: person_email)
      puts "updated E-mail on user record with user name #{user.oim_id} with person email"
    when "switch"
      user.update_attributes(email: 'ceciliopenado@gmail.com', oim_id: 'ceciliopenado@gmail.com')
      puts "updated E-mail & user name on user record to #{user.oim_id}"
    else
      puts "check how this record came here, user record is - #{user.inspect}"
    end
  else
    puts "Issues with record with user name - #{user.first.oim_id}"
  end
end


def action_on_headless_records

  CSV.foreach("spec/test_data/duplicate_users.csv", encoding:'iso-8859-1:utf-8') do |row|

    user_name, user_email, person_email, person_hbx_id, user_first_name, user_last_name, created_at, duplicate = row
    if duplicate.present?
      u = User.where(oim_id: user_name)
      if u.present?
        action(u, person_email, duplicate)
      else
        puts "user not exist with user name - #{user_name}"
      end
    end
  
  end
end
