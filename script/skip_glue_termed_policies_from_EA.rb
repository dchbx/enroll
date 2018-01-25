require 'csv'

csv_match = CSV.open("/Users/Varun/Desktop/reports/oct_14/11455_elimate_termed_canceled_oct_17.csv", "w")
csv_match << %w(family.id policy.id policy.subscriber.coverage_start_on policy.plan policy.renewal_plan policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.subscriber.person.hbx_id person.age policy.subscriber.person.is_incarcerated policy.subscriber.person.citizen_status policy.subscriber.person.is_dc_resident? is_dependent)

begin
	csv = CSV.open('/Users/Varun/Desktop/reports/oct_14/final_ea_report_oct_17_copy.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
  @data= csv.to_a
  @data_hash = {}
  @data.each do |d|
    if @data_hash[d["family.id"]].present?
      hbx_ids = @data_hash[d["family.id"]].collect{|r| r['policy.subscriber.person.hbx_id']}
      next if hbx_ids.include?(d["policy.subscriber.person.hbx_id"])
      @data_hash[d["family.id"]] << d
    else
      @data_hash[d["family.id"]] = [d]
    end
  end
  unwanted_families = []
  @data_hash.each do |family_id,members|
    members.each do |member|
      if member["policy.aasm_state"] == "terminated" || member["policy.aasm_state"] == "canceled"
        unwanted_families << family_id
      end
    end
  end

  @data_hash.reject!{|family_id,rows| unwanted_families.include?(family_id) }

  @data_hash.each do |family_id,members|
    members.each do |member|
      csv_match.add_row(member)
    end
  end

rescue Exception => e
  puts "Unable to open file #{e} #{e.backtrace}"
end
