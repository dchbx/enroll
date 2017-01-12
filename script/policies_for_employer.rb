qs = Queries::PolicyAggregationPipeline.new

feins = %w(
)

clean_feins = feins.map do |f|
  f.gsub(/\D/,"")
end

qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => Date.new(2016,9,30)}).eliminate_family_duplicates

enroll_pol_ids = []

qs.evaluate.each do |r|
  enroll_pol_ids << r['hbx_id']
end

glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)

missing = (enroll_pol_ids - glue_list)

missing.each do |m|
      puts m
end
