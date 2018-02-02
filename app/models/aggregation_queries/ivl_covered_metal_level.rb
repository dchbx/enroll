# "tile": "left_metal",
# "platinum_count": 3337,
# "platinum_share": 0.16,
# "platinum_yoy": 0.01,
# "gold_count": 4277,
# "gold_share": 0.20,
# "gold_yoy": -0.15,
# "silver_count": 6333,
# "silver_share": 0.30,
# "silver_yoy": -0.07,
# "bronze_count": 5854,
# "bronze_share": 0.28,
# "bronze_yoy": 0.08,
# "catastrophic_count": 1465,
# "catastrophic_share": 0.07,
# "catastrophic_yoy": 0.09

# command to run
# ivl = AggregationQueries::IvlCoveredMetalLevel.new({current_year: 2017, previous_year: 2016}).run

module AggregationQueries
  class IvlCoveredMetalLevel
    attr_accessor :platinum_yoy, :gold_yoy, :silver_yoy, :bronze_yoy, :catastrophic_yoy, :current_year, :previous_year, :start_date, :end_date

    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
      [current_year, previous_year].each do |year|
        ["platinum_count", "gold_count", "silver_count", "bronze_count", "catastrophic_count", "all_metal_level_count"
         "platinum_share", "gold_share", "silver_share", "bronze_share", "catastrophic_share"].each do |v|
          self.class.send(:attr_accessor, "#{v}_#{year}")
          instance_variable_set("@#{v}_#{year}", 0.0)
        end
      end
    end

    def get_and_set_current_year_data
      @start_date = Date.new(current_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @platinum_count_2017 = by_metal_level("platinum")
      @all_metal_level_count_2017 = total_metal_level_size
      @platinum_share_2017 = (platinum_count_2017/all_metal_level_count_2017).round(2)
      @gold_count_2017 = by_metal_level("gold")
      @gold_share_2017 = (gold_count_2017/all_metal_level_count_2017).round(2)
      @silver_count_2017 = by_metal_level("silver")
      @silver_share_2017 = (silver_count_2017/all_metal_level_count_2017).round(2)
      @bronze_count_2017 = by_metal_level("bronze")
      @bronze_share_2017 = (bronze_count_2017/all_metal_level_count_2017).round(2)
      @catastrophic_count_2017 = by_metal_level("catastrophic")
      @catastrophic_share_2017 = (catastrophic_count_2017/all_metal_level_count_2017).round(2)
    end

    def get_and_set_past_year_data
      @start_date = Date.new(previous_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @all_metal_level_count_2016 = total_metal_level_size
      @platinum_count_2016 = by_metal_level("platinum")
      @platinum_share_2016 = (platinum_count_2016/all_metal_level_count_2016).round(2)
      @gold_count_2016 = by_metal_level("gold")
      @gold_share_2016 = (gold_count_2016/all_metal_level_count_2016).round(2)
      @silver_count_2016 = by_metal_level("silver")
      @silver_share_2016 = (silver_count_2016/all_metal_level_count_2016).round(2)
      @bronze_count_2016 = by_metal_level("bronze")
      @bronze_share_2016 = (bronze_count_2016/all_metal_level_count_2016).round(2)
      @catastrophic_count_2016 = by_metal_level("catastrophic")
      @catastrophic_share_2016 = (catastrophic_count_2016/all_metal_level_count_2016).round(2)
    end

    def calculate_yoy
      @platinum_yoy = ((platinum_share_2017 - platinum_share_2016)/platinum_share_2016).round(2)
      @gold_yoy = ((gold_share_2017 - gold_share_2016)/gold_share_2016).round(2)
      @silver_yoy = ((silver_share_2017 - silver_share_2016)/silver_share_2016).round(2)
      @bronze_yoy = ((bronze_share_2017 - bronze_share_2016)/bronze_share_2016).round(2)
      @catastrophic_yoy = ((catastrophic_share_2017 - catastrophic_share_2016)/catastrophic_share_2016).round(2)
    end

    def result
      {
        tile: "left_metal",
        platinum_count: @platinum_count_2017, platinum_share: @platinum_share_2017, platinum_yoy: @platinum_yoy,
        gold_count: @gold_count_2017, gold_share: @gold_share_2017, gold_yoy: @gold_yoy,
        silver_count: @silver_count_2017, silver_share: @silver_share_2017, silver_yoy: @silver_yoy,
        bronze_count: @bronze_count_2017, bronze_share: @bronze_share_2017, bronze_yoy: @bronze_yoy,
        catastrophic_count: @catastrophic_count_2017, catastrophic_share: @catastrophic_share_2017, catastrophic_yoy: @catastrophic_yoy,
      }
    end

    def run
      get_and_set_current_year_data
      get_and_set_past_year_data
      calculate_yoy
      result
    end

    def search_family_member_ids
      puts "*"*80
      puts "search_family_member_ids"
      Family.collection.aggregate([
        {"$unwind" => '$households'},
        {"$unwind" => '$households.hbx_enrollments'},
        {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
        {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
        {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
        {"$match" => {"households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES) + ["coverage_expired"] }}},
        {"$project" => {"_id" => 0, "family_member_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id"}},
      ], :allow_disk_use => true).map{|a| a[:family_member_id]}.flatten
    end

    def total_metal_level_size
      puts "*"*80
      puts "in total_metal_level_size"
      values = Family.collection.raw_aggregate([
        {"$unwind" => '$family_members'},
        {"$match" => {"family_members._id" => { "$in" => search_family_member_ids}}},
        {"$group" => { "_id" => {  }, "non_unique_persons" => { "$addToSet" => '$family_members.person_id'} }},
        {"$unwind" => "$non_unique_persons"},
        {"$unwind" => "$non_unique_persons"},
        {"$group" => {"_id" => 'persons', "unique_persons" => {"$addToSet" => '$non_unique_persons'}}},
        {"$unwind" => "$unique_persons"},
        {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
      ])
      t = values.first.present? ? values.first["count"].to_f : 0.0
      puts "total: #{t}"
      puts "*"*80
      t
    end

    def by_metal_level(metal_level_kind)
      puts "*"*80
      puts "by_Carrier : start #{start_date} :: end #{end_date}"
      plan_ids = Plan.where(active_year: start_date.year, coverage_kind: "health", market: "individual", metal_level: metal_level_kind).map(&:_id)

      data = Family.collection.aggregate([
        {"$unwind" => '$households'},
        {"$unwind" => '$households.hbx_enrollments'},
        {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
        {"$match" => {"households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES) + ["coverage_expired"] }}},
        {"$match" => {"households.hbx_enrollments.plan_id"=> { "$in" => plan_ids }}},
        {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
        {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
        {"$project" => {"_id" => 0, "family_member_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id"}},
      ], :allow_disk_use => true).map{|a| a[:family_member_id]}.flatten

      values = Family.collection.raw_aggregate([
        {"$unwind" => '$family_members'},
        {"$match" => {"family_members._id" => { "$in" => data}}},
        {"$group" => { "_id" => {  }, "non_unique_persons" => { "$addToSet" => '$family_members.person_id'} }},
        {"$unwind" => "$non_unique_persons"},
        {"$unwind" => "$non_unique_persons"},
        {"$group" => {"_id" => 'persons', "unique_persons" => {"$addToSet" => '$non_unique_persons'}}},
        {"$unwind" => "$unique_persons"},
        {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
      ])
      t = values.first.present? ? values.first["count"].to_f : 0.0
      puts "#{metal_level_kind} #{t}"
      puts "*"*80
      t
    end

  end
end

ivl = AggregationQueries::IvlCoveredMetalLevel.new({current_year: 2017, previous_year: 2016})
ivl.run