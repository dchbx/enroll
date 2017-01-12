# Given enrollment IDs, count heads
def count_members_for_hbx_ids(hbx_ids)
  auto_renew_member_count = Family.collection.aggregate([
    {"$match" => {"households.hbx_enrollments.hbx_id" => {"$in" => hbx_ids}}},
    {"$unwind" => "$households"},
    {"$unwind" => "$households.hbx_enrollments"},
    {"$match" => {"households.hbx_enrollments.hbx_id" => {"$in" => hbx_ids}, "households.hbx_enrollments.hbx_enrollment_members" => {"$ne" => nil}}},
    {"$unwind" => "$households.hbx_enrollments.hbx_enrollment_members"},
    {"$group" => {"_id" => {"applicant_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id", "coverage_kind" => "$households.hbx_enrollments.coverage_kind"}}}
  ])

  auto_renew_member_count.count
end

# Gimme all the 2017s
qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_individual.filter_to_active.with_effective_date({"$gt" => Date.new(2016,12,31)}).eliminate_family_duplicates

qs.add({ "$match" => {"policy_purchased_at" => {"$gt" => Time.mktime(2016,10,25,0,0,0)}}})

EnrollSet = Struct.new(:coverage_kinds, :enrollments)
EnrollmentInfo = Struct.new(:enrollment_id, :state)

disposition_hash = Hash.new { |h, k| h[k] = EnrollSet.new([], []) }

selected_dispositions = qs.evaluate.inject(disposition_hash) do |dh, r|
  current_record = dh[r['_id']['family_id']]
  dh[r['_id']['family_id']] = EnrollSet.new(current_record.coverage_kinds << r['coverage_kind'], current_record.enrollments << EnrollmentInfo.new(r['hbx_id'], r['aasm_state']))
  dh
end

health_only_enrollments = selected_dispositions.values.select { |sd| sd.coverage_kinds.include?("dental") && sd.coverage_kinds.include?("health") }.map(&:enrollments).flatten

enroll_pol_ids = health_only_enrollments.map(&:enrollment_id)
all_ivl_count = health_only_enrollments.length
puts "2017 Both Enrollment Count: #{all_ivl_count}"
# Select 2017 enrollments in the "auto_renewing" state

auto_renew_pol_ids = health_only_enrollments.select { |ei| ei.state == "auto_renewing" }.map(&:enrollment_id)
auto_renew_count = auto_renew_pol_ids.count
puts "Auto Renewed Enrollment Count: #{auto_renew_count}"

auto_renew_member_count = count_members_for_hbx_ids(auto_renew_pol_ids)
puts "Total passively renewed covered lives: #{auto_renew_member_count}"

# Select enrollments which are NOT in "auto_renewing"
customer_purchased_enrollments = enroll_pol_ids - auto_renew_pol_ids

puts "Total actively selected 2017 enrollments: #{customer_purchased_enrollments.length}"

active_selection_member_count = count_members_for_hbx_ids(customer_purchased_enrollments)
puts "Total actively selected covered lives: #{active_selection_member_count}"

# Select all the "new" enrollments 
active_selection_families = Family.where("households.hbx_enrollments.hbx_id" => {"$in" => customer_purchased_enrollments})

active_selection_new_enrollments = []
active_selection_families.each do |fam|
  all_policies = fam.households.flat_map(&:hbx_enrollments)
  policies_for_2017 = all_policies.select { |pol| customer_purchased_enrollments.include?(pol.hbx_id) }
  policies_for_2017.each do |policy_for_2017|
    found_a_2016 = all_policies.any? do |pol|
      ((pol.effective_on <=  Date.new(2016,12,31)) &&
        (pol.effective_on >  Date.new(2015,12,31))) &&
      ((pol.terminated_on.blank?) || (!(pol.terminated_on < Date.new(2015,12,31)))) &&
      ((!pol.plan_id.blank?) && (pol.coverage_kind == policy_for_2017.coverage_kind)) &&
      (pol.is_shop? == policy_for_2017.is_shop?)
    end
    if !found_a_2016
      active_selection_new_enrollments << policy_for_2017.hbx_id
    end
  end
end

puts "Total new 2017 enrollments: #{active_selection_new_enrollments.length}"

new_members_count = count_members_for_hbx_ids(active_selection_new_enrollments)
puts "Total new covered lives: #{new_members_count}"

active_renewals = customer_purchased_enrollments - active_selection_new_enrollments
puts "Total Active Renewal 2017 enrollments: #{active_renewals.length}"
active_renewal_members = count_members_for_hbx_ids(active_renewals)
puts "Total actively renewed covered lives: #{active_renewal_members}"
