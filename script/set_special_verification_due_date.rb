def get_families
  Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent")
end

def families_without_spec_date
  Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent", :'households.hbx_enrollments.special_verification_period' => {:$exists => 0})
end


def set_date
  families = get_families
  problem_counter = 0
  families.each do |family|
    begin
      enrollment = family.active_household.hbx_enrollments.verification_needed.first
      enrollment.special_verification_period = Date.new(2016, 5, 30) + 95.days
      enrollment.save
    rescue => e
      problem_counter +=1
      puts "*** Problem #{problem_counter} ***"
      puts "The problem occurred for family with id: #{family.id}, Hbx enrollment id: #{enrollment.id}."
      puts e.message
      puts "***********************************"
    end
    if problem_counter > 0
      puts "You have #{problem_counter} problems."
    end
  end
end

def check_result
  families = get_families
  not_updated = families.find_all{|family| family.active_household.hbx_enrollments.verification_needed.first.special_verification_period == nil }
  if not_updated.count > 0
    puts "#{not_updated.count} families still DON'T have special verification period."
    not_updated.each{|family| puts "Family id: #{family.id}"}
  else
    puts "Perfect! All the records were fixed."
  end
end

def init_fix
  puts "#{families_without_spec_date.count} families need to be fixed."
  puts "***************************************************"
  puts "** START datafix script... **"
  set_date
  puts "...."
  puts "****** AFTER fix checking ******"
  check_result
end

init_fix





