# command to run
# ivl = AggregationQueries::IvlCoveredAptc.new({current_year: 2017, previous_year: 2016}).run
module AggregationQueries
  class IvlCoveredAptc
    attr_accessor :yes_yoy, :no_yoy, :current_year, :previous_year, :start_date, :end_date

    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
      [current_year, previous_year].each do |year|
        ["yes_count", "total_count", "yes_share", "no_count", "no_share"].each do |v|
          self.class.send(:attr_accessor, "#{v}_#{year}")
          instance_variable_set("@#{v}_#{year}", 0.0)
        end
      end
    end

    def get_and_set_current_year_data
      @start_date = Date.new(current_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @yes_count_2017 = search_ivl_users_with_aptc
      @total_count_2017 = total_ivl_users
      @no_count_2017 = total_count_2017 - yes_count_2017
      @yes_share_2017 = (yes_count_2017/total_count_2017).round(2)
      @no_share_2017 = 1.00 - yes_share_2017
    end

    def get_and_set_past_year_data
      @start_date = Date.new(previous_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @yes_count_2016 = search_ivl_users_with_aptc
      @total_count_2016 = total_ivl_users
      @no_count_2016 = total_count_2016 - yes_count_2016
      @yes_share_2016 = (yes_count_2016/total_count_2016).round(2)
      @no_share_2016 = 1.00 - yes_share_2016
    end

    def calculate_yoy
      @yes_yoy = ((yes_share_2017 - yes_share_2016)/yes_share_2016).round(2)
      @no_yoy = ((no_share_2017 - no_share_2016)/no_share_2016).round(2)
    end

    def result
      {
        tile: "left_aptc", yes_count: @yes_count_2017, yes_share: @yes_share_2017, yes_yoy: @yes_yoy,
        no_count: @no_count_2017, no_share: @no_share_2017, no_yoy: @no_yoy
      }
    end

    def run
      get_and_set_current_year_data
      get_and_set_past_year_data
      calculate_yoy
      result
    end

    def total_ivl_users
      values = Family.collection.aggregate([
        {"$unwind" => '$households'},
        {"$unwind" => '$households.hbx_enrollments'},
        {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
        {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
        {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
        {"$match" => {"households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES) + ["coverage_expired"] }}},
        {"$project" => {"_id" => 0, "family_member_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id"}},
        {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
      ])
      values.first.present? ? values.first["count"].to_f : 0.0
    end

    def search_ivl_users_with_aptc
      values = Family.collection.aggregate([
        {"$unwind" => '$households'},
        {"$unwind" => '$households.hbx_enrollments'},
        {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
        {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
        {"$match" => {"households.hbx_enrollments.applied_aptc_amount.cents" => {"$gt" => 0.0}}},
        {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
        {"$match" => {"households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES)+ ["coverage_expired"]}}},
        {"$project" => {"_id" => 0, "family_member_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id"}},
        {"$group" => { "_id" => "$_id", "count" => { "$sum" =>1 }}}
      ])
      values.first.present? ? values.first["count"].to_f : 0.0
    end

  end
end