module BenefitSponsors
  module Queries
    class BrokerFamiliesQuery

      def initialize(s_string, broker_agency_id, market_kind)
        @use_search = !s_string.blank?
        @search_string = s_string
        @broker_agency_profile_id = broker_agency_id
        @market_kind = market_kind
      end

      def build_base_scope
        ivl_broker_agency_criteria = { broker_agency_accounts: {:$elemMatch=> {benefit_sponsors_broker_agency_profile_id: @broker_agency_profile_id, is_active: true}} }
        shop_broker_agency_criteria = { "family_members.person_id" => {"$in" => employee_person_ids }}
        if @market_kind == :shop
          shop_broker_agency_criteria
        else
          { "$or" => [
            ivl_broker_agency_criteria,
            shop_broker_agency_criteria
          ]}
        end
      end

      def build_filtered_scope
        return build_base_scope unless @use_search
        person_id = build_people_id_criteria(@search_string)

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

      def employee_person_ids
        benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
          :broker_agency_accounts => {"$elemMatch" => {:benefit_sponsors_broker_agency_profile_id => @broker_agency_profile_id, is_active: true}}
        )

        @census_employee_ids ||= benefit_sponsorships.map { |bs| bs.census_employees.distinct(:_id) }.flatten

        employee_person_ids ||= Person.unscoped.where("employee_roles.census_employee_id" => {"$in" => @census_employee_ids}).pluck(:_id)
      end

      def build_people_id_criteria(s_string)
        clean_str = s_string.strip

        if clean_str =~ /[a-z]/i
          Person.collection.aggregate([
            {"$match" => {
              "$text" => {"$search" => clean_str}
            }.merge(Person.search_hash(clean_str))},
            {"$project" => {"first_name" => 1, "last_name" => 1, "hbx_id" => 1}},
            {"$sort" => {"last_name" => 1, "first_name" => 1}},
            {"$project" => {"_id" => 1}}
          ], {allowDiskUse: true}).map do |rec|
            rec["_id"]
          end
        else
          Person.search(s_string, nil, nil, true).pluck(:_id)
        end
      end
    end
  end
end
