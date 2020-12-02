require 'delegate'

AUDIT_START_DATE = Date.new(2018,10,1)
AUDIT_END_DATE = Date.new(2019,10,1)

STDOUT.puts "Standard caching complete."
STDOUT.flush

hbx = HbxProfile.current_hbx
bcps = hbx.benefit_sponsorship.benefit_coverage_periods
bcp = bcps.detect { |bcp| bcp.start_on.year == 2019 }
health_benefit_packages = bcp.benefit_packages.select do |bp|
  (bp.title.include? "health_benefits")
end

puts "Health Benefit Packages located."
STDOUT.flush

non_curam_ivl = Person.collection.aggregate([
  {"$project" => {
    _id: 1,
    created_at: 1,
    updated_at: 1,
    consumer_role: 1
  }},
  {"$match" => {
    "consumer_role._id" => {"$ne" => nil},
    "$or" => [
      {"created_at" => {"$gte" => AUDIT_START_DATE}},
      {"created_at" => {"$lt" => AUDIT_START_DATE}, "updated_at" => {"$gte" => AUDIT_START_DATE}}
    ]
  }},
  {"$project" => {_id: 1}}
])

ivl_person_ids = non_curam_ivl.map do |rec|
  rec["_id"]
end

STDOUT.puts "Counted #{ivl_person_ids.count} people."
STDOUT.flush

ivl_people = Person.where("_id" => {"$in" => ivl_person_ids})

families_of_interest = Family.where(
  {"family_members.person_id" => {"$in" => ivl_person_ids}}
)

STDOUT.puts "Counted #{families_of_interest.count} families."
STDOUT.flush

# Let's cache the family mappings
person_family_map = Hash.new { |h,k| h[k] = Array.new }

families_of_interest.each do |fam|
  fam.family_members.each do |fm|
    person_family_map[fm.person_id] = person_family_map[fm.person_id] + [fam]
  end
end

# So what we need here is: family_membership * person_record * version_numbers_for_person
person_id_count = ivl_person_ids.count
STDOUT.puts person_id_count.inspect
STDOUT.puts families_of_interest.count
STDOUT.flush

def relationship_for(person, family, version_date)
  return "self" if (person.id == family.primary_applicant.person_id)
  fm_person = family.primary_applicant.person_version_for(version_date)
  return "unrelated" unless fm_person
  fm_person.person_relationships.select { |r| r.relative_id.to_s == person.id.to_s}.first.try(:kind) || "unrelated"
end

def version_in_window?(updated_at)
  (updated_at >= AUDIT_START_DATE) && (updated_at < AUDIT_END_DATE)
end

def calc_eligibility_for(cr, family, benefit_packages, ed)
  effective_date = (ed < Date.new(2019,1,1)) ? Date.new(2019,1,1) : ed.to_date
  all_eligibilities = benefit_packages.map do |hbp|
    [
      hbp,
      InsuredEligibleForBenefitRule.new(cr, hbp, {new_effective_on: effective_date, family: family, version_date: ed, market_kind: "individual"}).satisfied?
    ]
  end
  eligible_value = all_eligibilities.any? do |ae|
    ae.last.first
  end
  eligibility_error_lookups = all_eligibilities.reject do |ae|
    ae.last.first
  end
  eligibility_errors = eligibility_error_lookups.map do |eel|
    {
      package: eel.first.title,
      errors: eel.last.last
    }.to_json
  end
  [eligible_value, eligibility_errors.join("\n")]
end

def home_address_for(person)
  home_address = person.home_address
  return([nil, nil, nil, nil, nil]) if home_address.blank?
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

def mailing_address_for(person)
  return([nil, nil, nil, nil, nil]) unless person.has_mailing_address?
  home_address = person.mailing_address
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

# Discard cases where we don't have a home OR mailing address for the primary
# We block them earlier in the process
def primary_has_address?(person, person_version, family)
   # If I'm the primary, do I have an address on this version?
  if (person.id == family.primary_applicant.person_id)
    !(person_version.home_address.blank? && person_version.mailing_address.blank?)
  else
    !(family.primary_applicant.person.home_address.blank? && family.primary_applicant.person.mailing_address.blank?)
  end
end

# Exclude individuals who have not even completed the application.
# They are blocked by the UI rules far earlier in the process.
def primary_answered_data?(person, person_version, family)
  if (person.id == family.primary_applicant.person_id)
    primary_person = person_version
    cr = primary_person.consumer_role
    return false if cr.blank?
    lpd = cr.lawful_presence_determination
    return false if lpd.blank?
    !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
  else
    primary_person = family.primary_applicant.person
    cr = primary_person.consumer_role
    return false if cr.blank?
    lpd = cr.lawful_presence_determination
    return false if lpd.blank?
    !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
  end
end

# Select only if curam is not the authorization authority
def not_authorized_by_curam?(person)
  cr = person.consumer_role
  return true if cr.blank?
  lpd = cr.lawful_presence_determination
  return true if lpd.blank?
  !(lpd.vlp_authority == "curam")
end

def determination_source_for(person)
  cr = person.consumer_role
  return "enroll" if cr.blank?
  lpd = cr.lawful_presence_determination
  return "enroll" if lpd.blank?
  (lpd.vlp_authority == "curam") ? "curam" : "enroll"
end

def auditable?(person_record, person_version, person_updated_at, family)
  version_in_window?(person_updated_at) &&
  primary_has_address?(person_record, person_version, family) &&
  primary_answered_data?(person_record, person_version, family)
end

pb = ProgressBar.create(
  :title => "Running records",
  :total => person_id_count,
  :format => "%t %a %e |%B| %P%%"
)
CSV.open("audit_ivl_determinations.csv", "w") do |csv|
  csv << [
    "Family ID",
    "Hbx ID",
    "Last Name",
    "First Name",
    "Full Name",
    "Date of Birth",
    "Gender",
    "Application Date",
    "Primary Applicant",
    "Relationship",
    "Citizenship Status",
    "American Indian",
    "Incarceration",
    "Home Street 1",
    "Home Street 2",
    "Home City",
    "Home State",
    "Home Zip",
    "Mailing Street 1",
    "Mailing Street 2",
    "Mailing City",
    "Mailing State",
    "Mailing Zip",
    "No DC Address",
    "Residency Exemption Reason",
    "Is applying for coverage",
    "Resident Role",
    "Determination Source",
    "Eligible",
    "Denial Reasons"
  ]
  ivl_people.no_timeout.each do |pers_record|
    person_versions = Versioning::PersonVersionCollection.new(pers_record)
    next unless person_versions.has_non_curam_determination?
    person_versions.each do |p_v|
      begin
      p_version = p_v.resolve_to_model
      person_updated_at = p_v.timestamp
      families = person_family_map[pers_record.id]
      # This "pers" variable will be the version that is appended to the CSV
      pers = p_version
      families.each do |fam|
        cr = pers.consumer_role
        if cr
          cr.person = p_version
          begin
            if auditable?(pers_record, p_version, person_updated_at, fam)
              eligible, eligibility_errors = calc_eligibility_for(cr, fam, health_benefit_packages, person_updated_at)
              lpd = cr.lawful_presence_determination
              if lpd
                address_fields = home_address_for(pers)
                mailing_address_fields = mailing_address_for(pers)
                csv << ([
                  fam.id,
                  pers.hbx_id,
                  pers.last_name,
                  pers.first_name,
                  pers.full_name,
                  pers.dob,
                  pers.gender,
                  person_updated_at.strftime("%Y-%m-%d %H:%M:%S.%L"),
                  (pers_record.id == fam.primary_applicant.person_id),
                  relationship_for(pers_record, fam, person_updated_at),
                  lpd.citizen_status,
                  (lpd.citizen_status.nil? ? nil : (lpd.citizen_status == "indian_tribe_member")),
                  pers.is_incarcerated] +
                  address_fields +
                  mailing_address_fields +
                  [
                    pers.no_dc_address,
                    pers.no_dc_address ? pers.no_dc_address_reason : "",
                    cr.is_applying_coverage,
                    pers.resident_role.present?,
                    determination_source_for(pers),
                    eligible,
                    eligible ? "" : eligibility_errors
                ])
              end
            end          
          rescue Mongoid::Errors::DocumentNotFound => e
            puts e.inspect
          end
        end
      end
      rescue HistoryTrackerReversalError => htre
        STDERR.puts htre.inspect
        STDERR.flush
        next
      end
    end
    person_family_map.delete(pers_record.id)
    pb.increment
  end
end
