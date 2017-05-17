require 'csv'
require 'date'

NPN_FIXES = [
  ["31134340", "3113434"],
  ["31131570", "3113157"],
  ["7865881", "78658810"],
  ["8944751", "89447510"]
]

NPN_FIXES.each do |npn_fix|
  found_broker_person = Person.where('broker_role.npn' => npn_fix.first).first
  if found_broker_person
    found_broker_person.broker_role.update_attributes!(npn: npn_fix.last)
  end
end

CSV.foreach("most_recent_brokers.csv", headers: true) do |row|
#  csv << %w(PROVIDERTYPE  PRODUCTTYPECT ENROLLMENTSTATUS  NPN PROVIDERNAME  CLIENT_NAME SSN DOB CARRIER USER_ACCOUNT  PROVIDERSTATUS  STARTDATE ENDDATE STARTDATEISO)
    r_hash = row.to_hash
    d = Date.strptime(r_hash['STARTDATEISO'], "%Y-%m-%d")
    the_ssn = r_hash['SSN']
    the_npn = r_hash['NPN']
    found_person = Person.where(encrypted_ssn: Person.encrypt_ssn(the_ssn)).first
    unless found_person
      puts "Could not find person for: #{row.fields.inspect}"
      next
    end
    found_family = found_person.primary_family
    unless found_family
      puts "Could not find primary family for: #{row.fields.inspect}"
      next
    end
    found_broker_person = Person.where('broker_role.npn' => the_npn).first
    unless found_broker_person
      puts "Could not find broker for: #{row.fields.inspect}"
      next
    end
    found_broker = found_broker_person.broker_role
    profile = found_broker.broker_agency_profile
    broker_agency_account = found_family.broker_agency_accounts.build({
      :start_on => d,
      :writing_agent_id => found_broker.id,
      :broker_agency_profile_id => profile.id
    })
    broker_agency_account.save!
end
