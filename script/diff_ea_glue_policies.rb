require 'csv'

def csv_to_hash(csv)
  hash = {}
  csv.each do |row|
    key = "#{row[0]}-#{row[5]}"
    hash[key] = [] if hash[key].nil?
    hash[key] = row
  end
  hash
end

def person_field_array(row)
  row.values_at(5, 6, 7, 8)
end

csv_glue = CSV.read("/Users/CitadelFirm/Downloads/10655-sep8/10655_export_glue_multi_row.csv")
csv_ea = CSV.read("/Users/CitadelFirm/Downloads/10655-sep8/10655_export_ea_multi_row.csv")

csv_match = CSV.open("matching_people.csv", "w")
csv_match << %w(policy_eg_id glue_person.hbx_id glue_incarcerated glue_citizenship glue_dc_resident ea_person.hbx_id, ea_incarcerated, ea_citizenship ea_dc_resident)

csv_mismatch = CSV.open("mismatching_people.csv", "w")
csv_mismatch << %w(policy_eg_id glue_person.hbx_id glue_incarcerated glue_citizenship glue_dc_resident ea_person.hbx_id, ea_incarcerated, ea_citizenship ea_dc_resident)


glue_hash = csv_to_hash(csv_glue)
ea_hash = csv_to_hash(csv_ea)

#key = policy-id_perosn-hbx-id
glue_hash.each do |key, row|
  next if ea_hash[key].nil?
  if (person_field_array(row) <=> person_field_array(ea_hash[key])) != 0
    csv_mismatch << [row[0]] + person_field_array(row) + person_field_array(ea_hash[key])
  else
    csv_match << [row[0]] + person_field_array(row) + person_field_array(ea_hash[key])
  end
end


