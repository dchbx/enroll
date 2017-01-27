module Queries
  class PolicyAggregationPipeline
    include QueryHelpers

    attr_reader :pipeline

    def initialize
      @pipeline = base_pipeline
    end

    def base_pipeline
      [
        { "$unwind" => "$households"},
        { "$unwind" => "$households.hbx_enrollments"},
        { "$match" => {"households.hbx_enrollments" => {"$ne" => nil}}},
        { "$match" => {"households.hbx_enrollments.hbx_enrollment_members" => {"$ne" => nil}, "households.hbx_enrollments.external_enrollment" => {"$ne" => true}}}
      ]
    end

    def add(step)
      @pipeline << step.to_hash
    end

    def evaluate
      Family.collection.aggregate(@pipeline)
    end

    def count
      list_of_hbx_ids.count
    end

    def open_enrollment
      add({
          "$match" => {
                "households.hbx_enrollments.enrollment_kind" => "open_enrollment"
          }
      })
      self
    end

    def filter_to_employers_hbx_ids(hbx_id_list)
      orgs = Organization.where(:hbx_id => {"$in" => hbx_id_list})
      benefit_group_ids = orgs.map(&:employer_profile).flat_map(&:plan_years).flat_map(&:benefit_groups).map(&:id)
      add({
          "$match" => {
                "households.hbx_enrollments.benefit_group_id" => { "$in" => benefit_group_ids }
                  }
      })
      self
    end

    def exclude_employers_by_hbx_ids(hbx_id_list)
      orgs = Organization.where(:hbx_id => {"$in" => hbx_id_list})
      benefit_group_ids = orgs.map(&:employer_profile).flat_map(&:plan_years).flat_map(&:benefit_groups).map(&:_id)
      add({
          "$match" => {
                "households.hbx_enrollments.benefit_group_id" => { "$nin" => benefit_group_ids }
          }
      })
      self
    end

    def filter_to_employers_feins(fein_list)
      orgs = Organization.where(:fein => {"$in" => fein_list})
      benefit_group_ids = orgs.map(&:employer_profile).flat_map(&:plan_years).flat_map(&:benefit_groups).map(&:id)
      add({
          "$match" => {
                "households.hbx_enrollments.benefit_group_id" => { "$in" => benefit_group_ids }
                  }
      })
      self
    end

    def filter_to_shopping_completed
      add({
        "$match" => {
          "households.hbx_enrollments.plan_id" => { "$ne" => nil},
          "households.hbx_enrollments.aasm_state" => { "$nin" => [
            "shopping", "inactive"
          ]}
        }
      })
      self
    end

    # TODO: Fix me to use the master list of statuses
    def filter_to_active
      add({
        "$match" => {
          "households.hbx_enrollments.plan_id" => { "$ne" => nil},
          "households.hbx_enrollments.aasm_state" => { "$in" => 
            (HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES)
          }
        }
      })
      self
    end

    def filter_to_individual
      add({
        "$match" => {
          "households.hbx_enrollments.consumer_role_id" => {"$ne" => nil},
          "households.hbx_enrollments.aasm_state" => { "$ne" => "shopping" } }
      })
      self
    end

    def with_effective_date(criteria)
      add({
        "$match" => {
          "households.hbx_enrollments.effective_on" => criteria
        }
      })
      self
    end

    def filter_to_shop
      add({
        "$match" => {
          "households.hbx_enrollments.aasm_state" => { "$ne" => "shopping" },
          "$or" => [
            {"households.hbx_enrollments.consumer_role_id" => {"$exists" => false}},
            {"households.hbx_enrollments.consumer_role_id" => nil}
          ]
        }
      })
      self
    end

    def list_of_hbx_ids
      add({
        "$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}
      })
      results = evaluate
      results.map do |h|
        h["_id"]
      end
    end

    def hbx_id_with_purchase_date_and_time
      add({
        "$project" => {
          "policy_purchased_at" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] },
          "policy_purchased_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
                                "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
          }
          },
          "hbx_id" => "$households.hbx_enrollments.hbx_id"
        }})
      yield self if block_given?
      results = self.evaluate
      results.map do |r|
        r['hbx_id']
      end
    end

    def remove_duplicates_by_family_as_non_renewals
      eliminate_family_duplicates
      add({
        "$match" => {"aasm_state" => {"$ne" => "auto_renewing"}}
      })
      purchased_on_grouping
    end

    def remove_duplicates_by_family_as_renewals
      eliminate_family_duplicates
      add({
        "$match" => {"aasm_state" => "auto_renewing"}
      })
      purchased_on_grouping
    end

    def remove_duplicates_by_family_as_sep
      eliminate_family_duplicates
      add({
        "$match" => {"enrollment_kind" => {"$ne" => "open_enrollment"}}
      })
      purchased_on_grouping
    end


    def remove_duplicates_by_family_as_open_enrollment
      eliminate_family_duplicates
      add({
        "$match" => {"enrollment_kind" => "open_enrollment"}
      })
      purchased_on_grouping
    end

    def dental
      add({
        "$match" => {"households.hbx_enrollments.coverage_kind" => "dental"}
      })
      self
    end

    def health
      add({
        "$match" => {"households.hbx_enrollments.coverage_kind" => "health"}
      })
      self
    end

    def filter_criteria_expression
        project_property("hbx_enrollment_members", "$households.hbx_enrollments.hbx_enrollment_members") +
        project_property("policy_start_on", "$households.hbx_enrollments.effective_on") +
        project_property("policy_end_on", "$households.hbx_enrollments.terminated_on") +
        project_property("family_created_at", "$created_at") +
        project_property("policy_purchased_at", { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }) +
=begin
        Not supported by mongo < 3.0!
        project_property("policy_purchased_on", {
          "$dateToString" => {"format" => "%Y-%m-%d",
                              "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
        }}) +
=end
        project_property("member_count", {"$size" => "$households.hbx_enrollments.hbx_enrollment_members"}) + 
        project_property("plan_id", "$households.hbx_enrollments.plan_id") +
        project_property("enrollment_kind", "$households.hbx_enrollments.enrollment_kind") +
        project_property("aasm_state", "$households.hbx_enrollments.aasm_state") +
        project_property("hbx_id", "$households.hbx_enrollments.hbx_id") +
        project_property("coverage_kind", "$households.hbx_enrollments.coverage_kind") +
        project_property("family_id", "$_id") +
        rp_ids_expression +
        state_transitions_expression
    end

    def state_transitions_expression
      project_property(
        "state_transitions",
          { "$cond" =>
            [
              "$households.hbx_enrollments.workflow_state_transitions",
              {"$map" => {
                 "input" => "$households.hbx_enrollments.workflow_state_transitions",
                 "as" => "state_trans",
                 "in" => "$$state_trans.from_state"
              }},
              []
            ]
          } 
      )
    end

    def rp_ids_expression
      project_property(
        "rp_ids",
        { "$cond" =>
          [          
              {"$anyElementTrue" => {"$map" => {
                 "input" => "$households.hbx_enrollments.hbx_enrollment_members",
                 "as" => "en_member",
                 "in" => {"$eq" => ["$$en_member.is_subscriber", true]}
               }}},
               nil,
               {"$map" => {
                 "input" => "$households.hbx_enrollments.hbx_enrollment_members",
                 "as" => "en_member",
                 "in" => "$$en_member.applicant_id"
               }}
          ]
      }
      )

    end

    def denormalize
      add(denormalized_properties)
      add({"$out" => "report_sources_hbx_enrollment_statistics"})
    end

    def denormalized_properties
      filter_criteria_expression + 
        project_property("_id", "$households.hbx_enrollments._id")  +
        project_property("hbx_id", "$households.hbx_enrollments.hbx_id")  +
        project_property("consumer_role_id", "$households.hbx_enrollments.consumer_role_id") +
        project_property("benefit_group_id", "$households.hbx_enrollments.benefit_group_id") +
        project_property("benefit_group_assignment_id", "$households.hbx_enrollments.benefit_group_assignment_id")
    end

    def expand_filter_criteria
      add(filter_criteria_expression)
    end

    def eliminate_family_duplicates
      flow = (
        filter_criteria_expression >>
        sort_on({"policy_purchased_at" => 1}) >>
        group_by(
          {"family_id" => "$family_id", "coverage_kind" => "$coverage_kind", "rp_ids" => "$rp_ids", "policy_start_on" => "$policy_start_on"},
          last("policy_purchased_at") +
          last("policy_purchased_on") +
          last("hbx_id") +
          last("plan_id") +
          last("aasm_state") +
          last("enrollment_kind") +
          last("coverage_kind") +
          last("family_created_at") +
          last("hbx_enrollment_members")
        ))
      @pipeline = @pipeline + flow.to_pipeline
      self
    end

    def remove_duplicates_by_family
      eliminate_family_duplicates
      purchased_on_grouping
    end

    def group_by_purchase_date
      add({
        "$project" => {
          "policy_purchased_at" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] },
          "policy_purchased_on" => {
            "$dateToString" => {"format" => "%Y-%m-%d",
                                "date" => { "$ifNull" => ["$households.hbx_enrollments.created_at", "$households.hbx_enrollments.submitted_at"] }
          }
          }
        }})
      yield self if block_given?
      purchased_on_grouping
    end

    def purchased_on_grouping
      add(
        group_by(
          {"purchased_on" => "$policy_purchased_on"},
          {"count" => {"$sum" => 1}}
        )
      )
      h = evaluate.inject({}) do |acc,r|
        k = r["_id"]["purchased_on"]
        if acc.has_key?(k)
          acc[k] = acc[k] + r["count"]
        else
          acc[k] = r["count"]
        end
        acc
      end
      result = h.keys.sort.map do |k|
        [k, h[k]]
      end
      total = result.inject(0) do |acc, i|
        acc + i.last
      end
      result << ["Total     ", total]
    end
  end
end
