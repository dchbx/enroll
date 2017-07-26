# Locates people with incorrectly formatted suffixes

permitted_suffixes = [nil,"","Jr.","Sr.","II","III","IV","V"]

corrections_needed = Person.where(:name_sfx => {"$nin" => permitted_suffixes})

def corrected_suffix(suffix,permitted_suffixes)
  if suffix.blank?
    return nil
  end
  if ["jr","jr."].include?(suffix.downcase.strip)
    return "Jr."
  elsif ["sr","sr."].include?(suffix.downcase.strip)
    return "Sr."
  elsif ["ii","2","two","2nd","second"].include?(suffix.downcase.strip)
    return "II"
  elsif ["iii","3","three","3rd","third"].include?(suffix.downcase.strip)
    return "III"
  elsif ["iv","4","four","4th","fourth"].include?(suffix.downcase.strip)
    return "IV"
  elsif ["v","5","five","5th","fifth"].include?(suffix.downcase.strip)
    return "V"
  end
end

def suffix_appearance_time(versions,suffix)
  return versions.sort_by{|v| v.updated_at}.detect{|v| v.name_sfx == suffix}.updated_at rescue nil
end

CSV.open("people_with_potential_bad_suffixes.csv","w") do |csv|
  csv << ["HBX ID","Name Prefix","First Name","Middle Name","Last Name","Name Suffix","DOB","SSN","Gender",
          "Person Creation Date/Time", "Suffix Creation Date/Time","Potential Correct Suffix"]
  corrections_needed.each do |person|
    hbx_id = person.hbx_id
    prefix = person.name_pfx
    first = person.first_name
    middle = person.middle_name
    last = person.last_name
    suffix = person.name_sfx
    dob = person.dob
    ssn = person.ssn
    gender = person.gender
    person_creation_time = person.created_at.strftime("%m/%d/%Y %I:%M:%S %p %z")
    if person.versions.size > 0
      suffix_creation_time = suffix_appearance_time(person.versions,suffix)
      if suffix_creation_time.blank?
        suffix_creation_time = person.updated_at.strftime("%m/%d/%Y %I:%M:%S %p %z")
      else
        suffix_creation_time = suffix_creation_time.strftime("%m/%d/%Y %I:%M:%S %p %z")
      end
    else
      suffix_creation_time = person.updated_at.strftime("%m/%d/%Y %I:%M:%S %p %z")
    end
    potential_correction = corrected_suffix(suffix,permitted_suffixes)
    csv << [hbx_id,prefix,first,middle,last,suffix,dob,ssn,gender,person_creation_time,suffix_creation_time,potential_correction]
  end
end