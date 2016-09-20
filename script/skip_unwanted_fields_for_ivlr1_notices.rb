require 'csv'

# csv_ea = CSV.read("/Users/Varun/Documents/DCHBX/enroll/matching_people_sep_19_change_status_copy.csv", :headers => true)
csv_match = CSV.open("/Users/Varun/Desktop/reports/sep_20/final_report_sep_20.csv", "w")
csv_match << %w(family_id	glue_eg_id	ea_eg_id	glue_aasm_state	ea_aasm_state	glue_hbx_id	ea_hbx_id	glue_incarcerated	glue_citizenship	glue_dc_resident	ea_incarcerated	ea_citizenship	ea_dc_resident)

# csv_mismatch = CSV.open("final_report_2.csv", "w")
# csv_mismatch << %w(family_id	glue_eg_id	ea_eg_id	glue_aasm_state	ea_aasm_state	glue_hbx_id	ea_hbx_id	glue_incarcerated	glue_citizenship	glue_dc_resident	ea_incarcerated	ea_citizenship	ea_dc_resident)

begin
	csv = CSV.open('/Users/Varun/Desktop/matching_people_sep_19_change_status_term_canceled.csv',"r",:headers =>true)
  @data= csv.to_a
  @data_hash = {}
  @data.each do |d|
    if @data_hash[d["family_id"]].present?
      hbx_ids = @data_hash[d["family_id"]].collect{|r| r['glue_hbx_id']}
      next if hbx_ids.include?(d["glue_hbx_id"])
      @data_hash[d["family_id"]] << d
    else
      @data_hash[d["family_id"]] = [d]
    end
  end
  unwanted_families = []
  @data_hash.each do |family_id,members|
    members.each do |member|
      # binding.pry
      if member["ea_incarcerated"].nil? || member["ea_incarcerated"] == "TRUE" || member["ea_citizenship"].nil? || member["ea_dc_resident"].nil? || member["ea_citizenship"] == "non_native_not_lawfully_present_in_us" || member["ea_citizenship"] == "not_lawfully_present_in_us" || member["ea_citizenship"] == "lawful_permanent_resident" || member["ea_dc_resident"] == "FALSE"
        unwanted_families << family_id
      end
    end
  end

  @data_hash.reject!{|family_id,rows| unwanted_families.include?(family_id) }

  @data_hash.each do |family_id,members|
    members.each do |member|
      # binding.pry
      csv_match.add_row(member)
    end
  end

rescue Exception => e
  puts "Unable to open file #{e} #{e.backtrace}"
end

# next if x[4] == "terminated" || x[4] == "canceled" ||  x[10] == nil || x[10] == "TRUE" || x[11] == nil || x[11] == "non_native_not_lawfully_present_in_us" || x[11] == "not_lawfully_present_in_us" || x[11] == "lawful_permanent_resident" || x[12] == "FALSE"