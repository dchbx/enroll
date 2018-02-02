# carrier
# "tile": "left_carrier",
# "carrier_first_name": "CareFirst",
# "carrier_first_count": 16315,
# "carrier_first_share": 0.81,
# "carrier_first_yoy": 0.0,
# "carrier_second_name": "Kaiser",
# "carrier_second_count": 3815,
# "carrier_second_share": 0.19,
# "carrier_second_yoy": 0.0

# command to run
# ivl = AggregationQueries::IvlCoveredCarrier.new({current_year: 2017, previous_year: 2016}).run
module AggregationQueries
  class IvlCoveredCarrier
    attr_accessor :carrier_first_yoy, :carrier_second_yoy, :current_year, :previous_year, :start_date, :end_date

    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
      [current_year, previous_year].each do |year|
        ["carrier_first_count", "carrier_second_count", "carrier_first_total_count", "carrier_second_total_count", "carrier_first_share", "carrier_second_share"].each do |v|
          self.class.send(:attr_accessor, "#{v}_#{year}")
          instance_variable_set("@#{v}_#{year}", 0.0)
        end
      end
    end

    def get_and_set_carrier_current_year_data
      @start_date = Date.new(current_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @carrier_first_count_2017 = by_carrier("care_first")
      @carrier_first_total_count_2017 = total_carrier_count
      @carrier_second_count_2017 = carrier_first_total_count_2017 - @carrier_first_count_2017
      @carrier_first_share_2017 = (carrier_first_count_2017/carrier_first_total_count_2017).round(2)
      @carrier_second_share_2017 = (1 - carrier_first_share_2017).round(2)
    end

    def get_and_set_carrier_past_year_data
      @start_date = Date.new(previous_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @carrier_first_count_2016 = by_carrier("care_first")
      @carrier_first_total_count_2016 = total_carrier_count
      @carrier_second_count_2016 = carrier_first_total_count_2016 - @carrier_first_count_2016
      @carrier_first_share_2016 = (carrier_first_count_2016/carrier_first_total_count_2016).round(2)
      @carrier_second_share_2016 = (1 - carrier_first_share_2016).round(2)
    end

    def calculate_yoy
      @carrier_first_yoy = ((carrier_first_share_2017 - carrier_first_share_2016)/carrier_first_share_2016).round(2)
      @carrier_second_yoy = ((carrier_second_share_2017 - carrier_second_share_2016)/carrier_second_share_2016).round(2)
    end

    def result
      {
        tile: "left_carrier",
        carrier_first_name: "CareFirst", carrier_first_count: carrier_first_count_2017, carrier_first_share: carrier_first_share_2017, carrier_first_yoy: carrier_first_yoy,
        carrier_second_name: "Kaiser", carrier_second_count: carrier_second_count_2017, carrier_second_share: carrier_second_share_2017, carrier_second_yoy: carrier_second_yoy,
      }
    end

    def run
      get_and_set_carrier_current_year_data
      get_and_set_carrier_past_year_data
      calculate_yoy
      result
    end

    def search_family_member_ids
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

    def total_carrier_count
      puts "*"*80
      puts "in total_carrier_count"
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
      values.first.present? ? values.first["count"].to_f : 0.0
    end

    def by_carrier(carrier_name)
      puts "*"*80
      puts "by_Carrier : start #{start_date} :: end #{end_date}"
      carrier_profile_id = carrier_name.downcase == "care_first" ? "53e67210eb899a4603000004" : "53e67210eb899a460300000d"
      plan_ids = Plan.where(active_year: start_date.year, coverage_kind: "health", market: "individual", carrier_profile_id: carrier_profile_id).map(&:_id)

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
      values.first.present? ? values.first["count"].to_f : 0.0
    end

  end
end

ivl = AggregationQueries::IvlCoveredCarrier.new({current_year: 2017, previous_year: 2016})
ivl.run