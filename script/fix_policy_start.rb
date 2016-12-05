def update_policy_start(pol_id, date)
  policy = HbxEnrollment.by_hbx_id(pol_id).first
  policy.effective_on = date
  policy.touch
  policy.household.touch
  policy.household.save!
  policy = HbxEnrollment.by_hbx_id(pol_id).first
  policy.hbx_enrollment_members.each do |hem|
    hem.eligibility_date = date
    hem.coverage_start_on = date
    hem.touch
  end
  policy.touch
  policy.household.touch
  policy.household.save!
  puts "#{pol_id} - #{date.to_s}"
end

eff_date_changes = {
  "479865" => Date.new(2016,6,1),
  "480705" => Date.new(2016,5,1)
}

eff_date_changes.each_pair do |k,v|
  update_policy_start(k, v)
end
