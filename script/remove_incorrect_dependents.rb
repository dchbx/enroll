def valid_dependent?(dependent,csv_data)
  return false unless csv_data.end_date.blank?
  csv_hbx_id = csv_data.hbx_id
  csv_ssn = csv_data.ssn
  csv_dob = csv_data.dob
  csv_first_name = csv_data.first_name
  csv_last_name = csv_data.last_name
  system_hbx_id = dependent.hbx_id
  system_dob = dependent.dob
  system_ssn = dependent.ssn
  system_first_name = dependent.first_name
  system_last_name = dependent.last_name

  hbx_id_result = compare_on_hbx_id(system_hbx_id,csv_hbx_id)
  ssn_result = compare_on_ssn(system_ssn,csv_ssn)
  name_dob_result = compare_on_name_and_dob(csv_first_name,csv_last_name,csv_dob,system_first_name,system_last_name,system_dob)
  results_array = [hbx_id_result,ssn_result,name_dob_result]
  if results_array.any?{|result| result == true}
    return true
  else
    return false
  end
end

def compare_on_hbx_id(system_hbx_id,csv_hbx_id)
  if system_hbx_id == csv_hbx_id
    return true
  else
    return false
  end
end

def compare_on_ssn(system_ssn,csv_ssn)
  if system_ssn == csv_ssn
    return true
  else
    return false
  end
end

def compare_on_name_and_dob(csv_first_name,csv_last_name,csv_dob,system_first_name,system_last_name,system_dob)
  csv_full_name = "#{csv_first_name.downcase.strip} #{csv_last_name.downcase.strip}"
  system_full_name = "#{system_first_name.downcase.strip} #{system_last_name.downcase.strip}"
  if csv_full_name == system_full_name && csv_dob == system_dob
    return true
  else
    return false
  end
end

def format_date(date)
  date = Date.strptime(date,'%m/%d/%Y')
end

def construct_csv_dependent(hbx_id,ssn,dob,first_name,last_name,end_date)
  csv_dependent = OpenStruct.new
  csv_dependent.hbx_id = hbx_id
  csv_dependent.ssn = ssn
  csv_dependent.dob = dob
  csv_dependent.first_name = first_name
  csv_dependent.last_name = last_name
  csv_dependent.end_date = end_date
  return csv_dependent
end

filename = '8905_dependents_incorrectly_migrated.csv'

CSV.foreach(filename,headers: true) do |csv_row|
  dependents_to_keep = []
  hbx_enrollment = HbxEnrollment.by_hbx_id(csv_row["Enrollment Group ID"]).first
  hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
    if hbx_em.is_subscriber?
      dependents_to_keep.push(hbx_em)
      next
    end
    results = []
    6.times do |i|
      if csv_row["HBX ID (Dep #{i+1})"] != nil
        csv_data = construct_csv_dependent(csv_row["HBX ID (Dep #{i+1})"],
                                         csv_row["SSN (Dep #{i+1})"].to_s.gsub("-",""),
                                         format_date(csv_row["DOB (Dep #{i+1})"]),
                                         csv_row["First Name (Dep #{i+1})"],
                                         csv_row["Last Name (Dep #{i+1})"],
                                         csv_row["Enrollee End Date (Dep #{i+1})"])
        results.push(valid_dependent?(hbx_em.person,csv_data))
      end
    end
    puts "#{hbx_em.person.full_name} - #{results}"
    if results.any?{|result| result == true}
      dependents_to_keep.push(hbx_em)
    end
  end
  puts dependents_to_keep
  hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
    unless dependents_to_keep.include?(hbx_em)
      hbx_em.destroy!
    end
  end
end
