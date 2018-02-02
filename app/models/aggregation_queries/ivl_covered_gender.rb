# "tile": "left_gender",
# "male_count": 10515,
# "male_share": 0.48,
# "male_yoy": -0.02,
# "female_count": 11371,
# "female_share": 0.52,
# "female_yoy": 0.02


# command to run
# ivl = AggregationQueries::IvlCoveredGender.new({current_year: 2017, previous_year: 2016}).run

module AggregationQueries
  class IvlCoveredGender
    attr_accessor :male_yoy, :female_yoy, :current_year, :previous_year, :start_date, :end_date

    def initialize(attributes={})
      attributes.each { |name, value| send("#{name}=", value) }
      [current_year, previous_year].each do |year|
        ["male_count", "total_count", "male_share", "female_count", "female_share"].each do |v|
          self.class.send(:attr_accessor, "#{v}_#{year}")
          instance_variable_set("@#{v}_#{year}", 0.0)
        end
      end
    end

    def get_and_set_current_year_data
      @start_date = Date.new(current_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @all_person_records = all_person_records
      @total_count_2017 = @all_person_records.size.to_f
      @male_count_2017 = search_male_count
      @female_count_2017 = total_count_2017 - male_count_2017
      @male_share_2017 = (male_count_2017/total_count_2017).round(4)
      @female_share_2017 = 1.00 - male_share_2017
    end

    def get_and_set_past_year_data
      @start_date = Date.new(previous_year,1,1).beginning_of_year
      @end_date = start_date.end_of_year
      @all_person_records = all_person_records
      @total_count_2016 = @all_person_records.size.to_f
      @male_count_2016 = search_male_count
      @female_count_2016 = total_count_2016 - male_count_2016
      @male_share_2016 = (male_count_2016/total_count_2016).round(4)
      @female_share_2016 = 1.00 - male_share_2016
    end

    def calculate_yoy
      @male_yoy = ((male_share_2017 - male_share_2016)/male_share_2016).round(4)
      @female_yoy = ((female_share_2017 - female_share_2016)/female_share_2016).round(4)
    end

    def result
      {
        tile: "left_gender",
        male_count: @male_count_2017, male_share: @male_share_2017, male_yoy: @male_yoy,
        female_count: @female_count_2017, female_share: @female_share_2017, female_yoy: @female_yoy
      }
    end

    def run
      get_and_set_current_year_data
      get_and_set_past_year_data
      calculate_yoy
      result
    end

    def all_person_records
      family_member_ids = Family.collection.aggregate([
        {"$unwind" => '$households'},
        {"$unwind" => '$households.hbx_enrollments'},
        {"$match" => {"households.hbx_enrollments.effective_on"=> {"$gte" => start_date, "$lte" => end_date}}},
        {"$match" => {"households.hbx_enrollments.coverage_kind"=> "health"}},
        {"$match" => {"households.hbx_enrollments.kind" => { "$in" => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]}}},
        {"$match" => {"households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES) + ["coverage_expired"] }}},
        {"$project" => {"_id" => 0, "family_member_id" => "$households.hbx_enrollments.hbx_enrollment_members.applicant_id"}},
      ], :allow_disk_use => true).map{|a| a[:family_member_id]}.flatten

      result = Family.collection.aggregate([
        {"$unwind" => '$family_members'},
        {"$match" => {"family_members._id" => { "$in" => family_member_ids}}},
        {"$project" => {"_id" => "$family_members.person_id"}}
      ]).map { |r| r['_id'].to_s }

      Person.where(:id.in => result)
    end

    def search_male_count
      all_person_records.where(gender: "male").size.to_f
    end

  end
end
