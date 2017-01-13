CSV.open("extracted_users_with_internal_roles.csv", "w") do |csv|
  csv << ["Oim_ID", "User Email", "HBX Member ID", "First Name", "Last Name", "Role Type"]
  Person.where(:hbx_staff_role.exists => true).each do |p|
    temp = Maybe.new(p)
    csv <<  [ temp.user.oim_id.extract_value,
              temp.user.email.extract_value,
              p.hbx_id,
              p.first_name,
              p.last_name,
              Permission.where(id: p.hbx_staff_role.permission_id).first.name
            ]
  end
  Person.where(:csr_role.exists => true).each do |p|
    temp = Maybe.new(p)
    csv <<  [ temp.user.oim_id.extract_value,
              temp.user.email.extract_value,
              p.hbx_id,
              p.first_name,
              p.last_name,
              "csr_role"
            ]
  end
  Person.where(:assister_role.exists => true).each do |p|
    temp = Maybe.new(p)
    csv <<  [ temp.user.oim_id.extract_value,
              temp.user.email.extract_value,
              p.hbx_id,
              p.first_name,
              p.last_name,
              "assister_role"
            ]
  end
end
