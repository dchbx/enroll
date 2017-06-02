namespace :role do
  desc "remove assister and cac roles from users"
  # Usage rake role:remove
  task :remove => [:environment] do
     
    CSV.foreach("bad_users.csv") do |row|
      email = row[2]
      role = row[3]
      hbx = row[4]
      
      if hbx.present?
        person = Person.where(hbx_id:hbx).first
        if role == "assister" && person.assister_role.present?
          person.assister_role.destroy
          person.update(is_disabled:true)
        elsif role == "cac" && person.csr_role.present?
          person.csr_role.destroy
          person.update(is_disabled:true)
        end
      elsif email.present?
        user = User.where(email:email).first
        if user.person.present?
          if role == "assister" && user.person.assister_role.present?
            user.person.assister_role.destroy
            user.person.update(is_disabled:true)
          elsif role == "cac" && user.person.csr_role.present?
            user.person.csr_role.destroy
            user.person.update(is_disabled:true)
          end
        end
      end
      
    end
    puts "Successfully removed roles"
  end
end

