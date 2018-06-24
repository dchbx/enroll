require "csv"

results = Hash.new {|h,k| h[k] = Array.new }
family_members = Hash.new {|h,k| h[k] = Array.new }
enrollments_with_multiples = Array.new
enrollment_status = Hash.new
enrollments_with_multiples_hash = Hash.new
roles_for_people_to_fix = Hash.new {|h,k| h[k] = Array.new }
people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})

enrollments_with_multiple_family_members = 0

people.each do |person|
  person.primary_family && person.primary_family.households.first.hbx_enrollments.each do |enrollment|
    if enrollment.kind == "coverall"
      #store
      roles_for_people_to_fix[person.hbx_id].push("consumer") if person.consumer_role?
      roles_for_people_to_fix[person.hbx_id].push("employee") if person.employee_roles?
      roles_for_people_to_fix[person.hbx_id].push("resident") if person.resident_role?
      results[person.hbx_id].push(enrollment.hbx_id)
      enrollment_status[enrollment.hbx_id] = enrollment.aasm_state
      #check to see if there are family_members on the enrollment
      if enrollment.hbx_enrollment_members.size != 1
        enrollments_with_multiple_family_members = enrollments_with_multiple_family_members + 1
        enrollments_with_multiples << enrollment.hbx_id
        enrollments_with_multiples_hash[enrollment.hbx_id] = enrollment.hbx_enrollment_members.size
      end
    end
  end
end

puts "These are the hbx_ids that currently have coverall enrollments"
puts results.keys

puts"\nAnd these are the enrollments associated with them that need to be updated in gluedb"
CSV.open("resident_enrollments_in_ea.csv", "wb") do |csv|
  csv << ["person.hbx_id", "enrollment.hbx_id", "enrollment status"]
  results.keys.each do |hbx_id|
    results[hbx_id].each do |enrollment_id|
      puts hbx_id + ": "  + enrollment_id + " status => " +  enrollment_status[enrollment_id]
      csv << [hbx_id, enrollment_id, enrollment_status[enrollment_id]]
    end
  end
end
puts "There are #{enrollments_with_multiple_family_members} that have multiple family_members."
if enrollments_with_multiples.size != 0
  puts "Here are those enrollments:"
  enrollments_with_multiples.each do |enrollment|
    puts "#{enrollment} : #{enrollments_with_multiples_hash[enrollment]}"
  end
end
puts "************************************"
r_role = ""
c_role = ""
e_role = ""
CSV.open("roles_for_people_to_fix.csv", "wb") do |csv|
  csv << ["hbx_id", "consumer", "employee", "resident"]
  roles_for_people_to_fix.keys.each do |hbx_id|
    #remove duplicates
    roles_for_people_to_fix[hbx_id] = roles_for_people_to_fix[hbx_id].uniq
    r_role = "resident" if roles_for_people_to_fix[hbx_id].include?("resident")
    e_role = "employee" if roles_for_people_to_fix[hbx_id].include?("employee")
    c_role = "consumer" if roles_for_people_to_fix[hbx_id].include?("consumer")
    puts "#{hbx_id} : #{roles_for_people_to_fix[hbx_id]}"
    csv << [hbx_id, c_role, e_role, r_role]
    r_role = ""
    c_role = ""
    e_role = ""
  end
end
puts "finished"
