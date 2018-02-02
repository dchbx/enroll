# "tile": "left_status",
# "primary_count": 19850,
# "primary_share": 0.82,
# "primary_yoy": 0.05,
# "dependent_count": 2445,
# "dependent_share": 0.18,
# "dependent_yoy": -0.10


# command to run
# ivl = AggregationQueries::IvlCoveredStatus.new({current_year: 2017, previous_year: 2016}).run

module AggregationQueries
  class IvlCoveredStatus
    attr_accessor :primary_yoy, :dependent_yoy, :current_year, :previous_year, :start_date, :end_date

    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
      [current_year, previous_year].each do |year|
        ["primary_count", "primary_share", "dependent_count", "dependent_share"].each do |v|
          self.class.send(:attr_accessor, "#{v}_#{year}")
          instance_variable_set("@#{v}_#{year}", 0.0)
        end
      end
    end

    def get_and_set_current_year_data
      @start_date = Date.new(current_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @all_count = search_primary_and_dependent
      @primary_count_2017 = search_primary_applicant
      @dependent_count_2017 = @all_count - @primary_count_2017
      @primary_share_2017 = (primary_count_2017/@all_count).round(2)
      @dependent_share_2017 = (1 - @primary_share_2017).round(2)
    end

    def get_and_set_past_year_data
      @start_date = Date.new(previous_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @all_count = search_primary_and_dependent
      @primary_count_2016 = search_primary_applicant
      @dependent_count_2016 = @all_count - @primary_count_2016
      @primary_share_2016 = (primary_count_2016/@all_count).round(2)
      @dependent_share_2016 = (1 - @primary_share_2016).round(2)
    end

    def calculate_yoy
      @primary_yoy = ((primary_share_2017 - primary_share_2016)/primary_share_2016).round(2)
      @dependent_yoy = ((dependent_share_2017 - dependent_share_2016)/dependent_share_2016).round(2)
    end

    def result
      {
        tile: "left_status",
        primary_count: @primary_count_2017, primary_share: @primary_share_2017, primary_yoy: @primary_yoy,
        dependent_count: @dependent_count_2017, dependent_share: @dependent_share_2017, dependent_yoy: @dependent_yoy
      }
    end

    def run
      get_and_set_current_year_data
      get_and_set_past_year_data
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

    def search_primary_applicant
      puts "*"*80
      puts "in search_primary_applicant"
      values = Family.collection.raw_aggregate([
        {"$unwind" => '$family_members'},
        {"$match" => {"family_members._id" => { "$in" => search_family_member_ids}}},
        {"$match" => {"family_members.is_primary_applicant"=> true}},
        {"$group" => { "_id" => {  }, "non_unique_persons" => { "$addToSet" => '$family_members.person_id'} }},
        {"$unwind" => "$non_unique_persons"},
        {"$unwind" => "$non_unique_persons"},
        {"$group" => {"_id" => 'persons', "unique_persons" => {"$addToSet" => '$non_unique_persons'}}},
        {"$unwind" => "$unique_persons"},
        {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
      ])
      values.first.present? ? values.first["count"].to_f : 0.0
    end

    def search_primary_and_dependent
      puts "*"*80
      puts "in search_primary_and_dependent"
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

    # def search_dependent
    #   puts "*"*80
    #   puts "in search_dependent"
    #   values = Family.collection.raw_aggregate([
    #     {"$unwind" => '$family_members'},
    #     {"$match" => {"family_members._id" => { "$in" => search_family_member_ids}}},
    #     {"$match" => {"family_members.is_primary_applicant"=> false}},
    #     {"$group" => { "_id" => {  }, "non_unique_persons" => { "$addToSet" => '$family_members.person_id'} }},
    #     {"$unwind" => "$non_unique_persons"},
    #     {"$unwind" => "$non_unique_persons"},
    #     {"$group" => {"_id" => 'persons', "unique_persons" => {"$addToSet" => '$non_unique_persons'}}},
    #     {"$unwind" => "$unique_persons"},
    #     {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
    #   ])
    #   t = values.first.present? ? values.first["count"].to_f : 0.0
    #   puts "count: #{t}"
    #   puts "*"*80
    #   t
    # end
  end
end