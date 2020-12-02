AUDIT_START_DATE = Date.new(2017,10,1)
AUDIT_END_DATE = Date.new(2018,10,1)

hbx = HbxProfile.current_hbx
bcps = hbx.benefit_sponsorship.benefit_coverage_periods
bcp = bcps.detect { |bcp| bcp.start_on.year == 2018 }
health_benefit_packages = bcp.benefit_packages.select do |bp|
  (bp.title.include? "health_benefits")
end

person_ids = %w(
18835009
19753098
19782602
19783647
19789625
19929102
19929329
19938554
19943999
19950345
19959144
19959202
19959676
19960015
19961673
19962623
19964029
19965510
19965516
19970172
19974467
19974929
19975021
19975156
19976883
19979723
19979890
19980268
19985251
19986700
19989568
19990938
19992639
19996700
20000788
20001422
20002629
20003154
20006058
20007366
20007660
20011071
20015905
)

non_curam_ivl = Person.collection.aggregate([
  {"$match" => {
#    "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"},
    "consumer_role" => {"$ne" => nil},
    "created_at" => {"$lt" => AUDIT_END_DATE} 
  }},
  {"$match" => {
    :hbx_id => {"$in" => person_ids},
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

ivl_people = Person.where("_id" => {"$in" => ivl_person_ids})

families_of_interest = Family.where(
  {"family_members.person_id" => {"$in" => ivl_person_ids}} #, "e_case_id" => nil}
)


# Let's cache the family mappings
person_family_map = Hash.new { |h,k| h[k] = Array.new }

families_of_interest.each do |fam|
  fam.family_members.each do |fm|
    person_family_map[fm.person_id] = person_family_map[fm.person_id] + [fam]
  end
end

# So what we need here is: family_membership * person_record * version_numbers_for_person
person_id_count = ivl_person_ids.count
puts person_id_count.inspect
puts families_of_interest.count

def relationship_for(person, family)
  return "self" if (person.id == family.primary_applicant.person_id)
  from_rel = person.find_relationship_with(family.primary_applicant.person)
  return from_rel if !from_rel.blank?
  family.primary_applicant.person.find_relationship_with(person)
end

def version_in_window?(pers)
  return true if pers.updated_at.blank?
  (pers.updated_at >= AUDIT_START_DATE) && (pers.updated_at < AUDIT_END_DATE)
end

def calc_eligibility_for(cr, family, benefit_packages, ed)
  benefit_packages.any? do |hbp|
    InsuredEligibleForBenefitRule.new(cr, hbp, {eligibility_date: ed, family: family}).satisfied?.first
  end
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

pb = ProgressBar.create(
  :title => "Running records",
  :total => person_id_count,
  :format => "%t %a %e |%B| %P%%"
)
CSV.open("audit_ivl_determinations_with_curam.csv", "w") do |csv|
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
    "Residency Exemption Reason",
    "Is applying for coverage",
    "Curam",
    "Eligible"
  ]
  ivl_people.each do |pers_record|
    families = person_family_map[pers_record.id]
    person_versions = [pers_record] + pers_record.versions
    person_versions.each do |pers|
      families.each do |fam|
        cr = pers.consumer_role
        if cr
          if cr.person.blank?
            cr.person = pers
          end
          begin
            if version_in_window?(pers) && primary_has_address?(pers_record, pers, fam) && primary_answered_data?(pers_record, pers, fam) # && not_authorized_by_curam?(pers)
              eligible = calc_eligibility_for(cr, fam, health_benefit_packages, pers.updated_at)
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
                  pers.updated_at.strftime("%Y-%m-%d %H:%M:%S.%L"),
                  (pers_record.id == fam.primary_applicant.person_id),
                  relationship_for(pers_record, fam),
                  lpd.citizen_status,
                  (lpd.citizen_status.nil? ? nil : (lpd.citizen_status == "indian_tribe_member")),
                  pers.is_incarcerated] +
                  address_fields +
                  mailing_address_fields +
                  [ 
                    pers.no_dc_address ? pers.no_dc_address_reason : "",
                    cr.is_applying_coverage,
                    !not_authorized_by_curam?(pers),
                    eligible 
                ])
              end
            end
          rescue Mongoid::Errors::DocumentNotFound => e
            puts e.inspect
          end
        end
      end
    end
    pb.increment
    person_family_map.delete(pers_record.id)
  end
end
