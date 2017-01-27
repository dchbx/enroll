qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_individual.filter_to_active.with_effective_date({"$gt" => Date.new(2016,9,1), "$lt" => Date.new(2017,1,1)}).eliminate_family_duplicates

enroll_pol_ids = []

qs.evaluate.each do |r|
    enroll_pol_ids << r['hbx_id']
end

glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)

missing = (enroll_pol_ids - glue_list)

missing.each do |m|
    puts m
end
