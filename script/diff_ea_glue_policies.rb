require 'csv'

def csv_to_hash(csv)
  hash = {}
  csv.each do |row|
    key = "#{row[1]}-#{row[6]}"
    hash[key] = [] if hash[key].nil?
    hash[key] = row
  end
  hash
end

def person_field_array(row)
  row.values_at(3)
end

csv_glue = CSV.read("/Users/Varun/Desktop/reports/10655_export_glue_multi_row_no_csr_no_aptc.csv")
csv_ea = CSV.read("/Users/Varun/Desktop/reports/10655_export_ea_multirow_sep_19_change_status.csv")

csv_match = CSV.open("matching_people_sep_19_change_status.csv", "w")
csv_match << %w(family_id glue_eg_id ea_eg_id glue_aasm_state ea_aasm_state glue_hbx_id ea_hbx_id glue_incarcerated glue_citizenship glue_dc_resident ea_incarcerated ea_citizenship ea_dc_resident)

csv_mismatch = CSV.open("mismatching_people_sep_19_change_status.csv", "w")
csv_mismatch << %w(family_id glue_eg_id ea_eg_id glue_aasm_state ea_aasm_state glue_hbx_id ea_hbx_id glue_incarcerated glue_citizenship glue_dc_resident ea_incarcerated ea_citizenship ea_dc_resident)


glue_hash = csv_to_hash(csv_glue)
ea_hash = csv_to_hash(csv_ea)

#key = policy-id_perosn-hbx-id
glue_hash.each do |key, row|
  next if ea_hash[key].nil?
  if (person_field_array(row) <=> person_field_array(ea_hash[key])) != 0
    csv_mismatch << [ea_hash[key][0]] + [row[1]] + [ea_hash[key][1]] + [row[3]] + [ea_hash[key][3]] + [row[6]] + [ea_hash[key][6]] + [row[7]] + [row[8]] + [row[9]] + [ea_hash[key][7]] + [ea_hash[key][8]] + [ea_hash[key][9]]
  else
    csv_match << [ea_hash[key][0]] + [row[1]] + [ea_hash[key][1]] + [row[3]] + [ea_hash[key][3]] + [row[6]] + [ea_hash[key][6]] + [row[7]] + [row[8]] + [row[9]] + [ea_hash[key][7]] + [ea_hash[key][8]] + [ea_hash[key][9]]
  end
end