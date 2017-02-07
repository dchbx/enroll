module Queries
  class BrokerFamiliesQuery

    def initialize(s_string, broker_agency_id)
      @use_search = !s_string.blank?
      @search_string = s_string
      @broker_agency_profile_id = broker_agency_id
    end

    def build_base_scope
      ivl_broker_agency_criteria = { broker_agency_accounts: {:$elemMatch=> {broker_agency_profile_id: @broker_agency_profile_id, is_active: true}} }
      shop_broker_agency_criteria = { "family_members.person_id" => {"$in" => employee_person_ids }}
      { "$or" => [
        ivl_broker_agency_criteria,
        shop_broker_agency_criteria
      ]}
    end

    def build_filtered_scope
      return build_base_scope unless @use_search
      person_id = Person.where(Person.search_hash(@search_string)).limit(700).pluck(:_id)
      {
        "$and" => [
          { 'family_members.person_id' => {"$in" => person_id} },
          build_base_scope
        ]
      }
    end

    def filtered_scope
      @filtered_scope ||= Family.where(build_filtered_scope)
    end

    def base_scope
      @base_scope ||= Family.where(build_base_scope)
    end

    def total_count
      base_scope.count
    end

    def filtered_count
      filtered_scope.count
    end

    def census_employee_ids
      @census_member_ids ||= CensusMember.collection.aggregate([
        { "$match" => {aasm_state: {"$in"=> CensusEmployee::EMPLOYMENT_ACTIVE_STATES}, employer_profile_id: {"$in" => employer_ids}}},
        { "$group" => {"_id" => "$_id"}}
      ]).map { |rec| rec["_id"] }
    end

    def employee_person_ids
      @employee_person_ids ||= Person.unscoped.where("employee_roles.census_employee_id" => {"$in" => census_employee_ids}).pluck(:_id)
    end

    def employer_ids
      @employer_ids ||= Organization.collection.aggregate([
        { "$match" => { :'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: @broker_agency_profile_id } } } },
        { "$group" => { "_id" => "$employer_profile._id" }}
      ]).map { |rec| rec["_id"] }
    end
  end
end
