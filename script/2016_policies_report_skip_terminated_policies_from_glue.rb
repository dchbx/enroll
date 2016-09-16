require 'csv'

csv_glue = CSV.read("/Users/Varun/Desktop/reports/10655_export_glue_multi_row_sep_16.csv", :headers => true)
csv_ea = CSV.read("/Users/Varun/Desktop/reports/10655_export_ea_multirow_sep_15.csv", :headers => true)

csv_match = CSV.open("glue_terminated_poilices.csv", "w")
csv_match << %w(family.id policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

csv_mismatch = CSV.open("final_ea_report.csv", "w")
csv_mismatch << %w(family.id  policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.subscriber.person.hbx_id policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident?  is_dependent)

terminated_glue_keys=csv_glue.select do |row| 
  row["policy.aasm_state"].downcase == 'terminated' 
end.flat_map{|r| r["policy.eg_id"]+"_"+r["person.authority_member_id"] }

csv_ea.each do |row|
  if terminated_glue_keys.include?(row["policy.id"]+"_"+row["policy.subscriber.person.hbx_id"])
    csv_match.add_row(row)
  else
    csv_mismatch.add_row(row) 
  end
end