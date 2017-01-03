qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_individual.filter_to_active.with_effective_date({"$gt" => Date.new(2016,12,31)}).eliminate_family_duplicates

qs.add({ "$match" => {"policy_purchased_at" => {"$gt" => Time.mktime(2016,11,1,0,0,0)}}})

all_active_selections = []

qs.evaluate.each do |r|
  if r['aasm_state'] != "auto_renewing"
    all_active_selections << r['hbx_id']
  end
end

active_selection_families = Family.where("households.hbx_enrollments.hbx_id" => {"$in" => all_active_selections})

active_selection_new_enrollments = []
active_selection_families.each do |fam|
  all_policies = fam.households.flat_map(&:hbx_enrollments)
  policies_for_2017 = all_policies.select { |pol| all_active_selections.include?(pol.hbx_id) }
  policies_for_2017.each do |policy_for_2017|
    found_a_2016 = all_policies.any? do |pol|
      ((pol.effective_on <=  Date.new(2016,12,31)) &&
       (pol.effective_on >  Date.new(2015,12,31))) &&
      ((pol.terminated_on.blank?) || (!(pol.terminated_on < Date.new(2015,12,31)))) &&
      ((!pol.plan_id.blank?) && (pol.coverage_kind == policy_for_2017.coverage_kind)) &&
      (pol.is_shop? == policy_for_2017.is_shop?)
    end
    if !found_a_2016
      if policy_for_2017.subscriber.present?
      if policy_for_2017.subscriber.family_member == policy_for_2017.household.family.primary_applicant
        active_selection_new_enrollments << policy_for_2017.hbx_id
      end
      end
    end
  end
end

glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)

missing = (active_selection_new_enrollments - glue_list)

missing.each do |m|
    puts m
end
