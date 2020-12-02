require 'csv'

require 'csv'

def timestamp
  Time.now.strftime('%m_%d_%Y_at_%H_%M')
end

def all_hbx_staff_role
  Person.all_hbx_staff_roles
end

def fields_for_record
  %w(user_id last_name first_name hbx_staff_sub_role created_at last_log_in deactived_on status)
end

def hbx_staff_people(active = true)
  users = Person.all_hbx_staff_roles.inject([]) do |arr, person|
    if !active
      arr << person if person.user && (person.user.oim_id.match(/.*disable/i).present? || person.user.oim_id.match(/.*do[-_]not[-_]/i).present? || person.user.oim_id.match(/.*access[-_]denied/i).present?)
    else
      arr << person if person.user && (!person.user.oim_id.match(/.*disable/i).present? && !person.user.oim_id.match(/.*do[-_]not[-_]/i).present? &&  !person.user.oim_id.match(/.*access[-_]denied/i).present?)
    end
    arr.flatten.compact.uniq
  end
end

def hbx_staff_people_active
  hbx_staff_people
end

def hbx_staff_people_inactive
  hbx_staff_people(false)
end

def hbx_role(person)
  person.hbx_staff_role
end

def last_login(person)
  #SessionIdHistory.for_user(user_id: person.user_id).order('created_at DESC').first.created_at
  user = person.user.blank? ? "no_user" : person.user.last_sign_in_at
end

def role_status(person)
  hbx_role(person).is_active? ? "active" : "inactive"
end

def build_record(person, active = true)
  user_id = person.user.blank? ? "no_user" : person.user.id
  updated_at = person.user.blank? ? "no_user" : person.user.updated_at
  [user_id, person.last_name, person.first_name, hbx_role(person).subrole, hbx_role(person).created_at, last_login(person), active ? "N/A" : updated_at, active ? role_status(person) : "inactive"]
end

CSV.open("internal_access_accounts_report_#{timestamp}.csv", "w") do |csv|
  empty_sub = fields_for_record.drop(1).map{''}
  csv << ["Report generated #{timestamp}"] + empty_sub
  csv << ["There are #{all_hbx_staff_role.count} people who have a hbx_staff_role"] + empty_sub
  csv << ["Genereating report ********************"] + empty_sub
  csv << ["Active Admins ********************"] + empty_sub
  csv << fields_for_record
  hbx_staff_people_active.each do |person|
    csv << build_record(person)
  end
  csv << [''] + empty_sub
  csv << ["Deactivated Admins ********************"] + empty_sub
  hbx_staff_people_inactive.each do |person|
    csv << build_record(person, false)
  end
  csv << ["End of Report ********************"] + empty_sub
end