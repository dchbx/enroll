module Queries
  class NamedEnrollmentQueries

    class EnrollmentCounter
      def initialize(last_chance_to_cancel, enums_from_aggregation)
        @last_chance_to_cancel = last_chance_to_cancel
        @source_enums = enums_from_aggregation 
      end

      def calculate_totals
        waived = 0
        enrolled = 0
        @source_enums.each do |agg|
          agg.each do |rec|
            if ["renewing_waived", "inactive", "void"].include?(rec["aasm_state"].to_s)
              waived = waived + 1
            else
              case passes_cancel_event_test?(rec)
              when false
              when :waiver
                waived = waived + 1
              else
                enrolled = enrolled + 1
              end
            end
          end
        end
        [enrolled, waived]
      end

      def passes_cancel_event_test?(record)
        unless (record['aasm_state'].to_s == "coverage_canceled")
          return (record['product_id'].blank? ? :waiver : true)
        end
        transitions = record['workflow_state_transitions']
        return false if transitions.blank?
        cancel_transitions = transitions.select do |trans|
          trans['to_state'].to_s == "coverage_canceled"
        end
        return false if cancel_transitions.blank?
        cancel_time = cancel_transitions.map { |ct| ct['transition_at'] }.compact.max
        return false if cancel_time.blank?
        return false if (cancel_time <= @last_chance_to_cancel)
        (record['product_id'].blank? ? :waiver : true)
      end
    end


    class InitialEnrollmentFilter
      include Enumerable

      def initialize(last_chance_to_cancel, enums_from_aggregation)
        @last_chance_to_cancel = last_chance_to_cancel
        @source_enums = enums_from_aggregation 
      end

      def each
        @source_enums.each do |agg|
          agg.each do |rec|
            unless ["renewing_waived", "inactive", "void"].include?(rec["aasm_state"].to_s)
              if passes_cancel_event_test?(rec)
                yield rec["hbx_enrollment_id"]
              end
            end
          end
        end
      end

      def passes_cancel_event_test?(record)
        unless (record['aasm_state'].to_s == "coverage_canceled")
          return (!record['product_id'].blank?) # Waiver canceled/termed later
        end
        return false if record['product_id'].blank? # Canceled or terminated waiver
        return true unless (record['aasm_state'].to_s == "coverage_canceled")
        transitions = record['workflow_state_transitions']
        return false if transitions.blank?
        cancel_transitions = transitions.select do |trans|
          trans['to_state'].to_s == "coverage_canceled"
        end
        return false if cancel_transitions.blank?
        cancel_time = cancel_transitions.map { |ct| ct['transition_at'] }.compact.max
        return false if cancel_time.blank?
        cancel_time > @last_chance_to_cancel
      end
    end

    class RenewalTransmissionEligibleFilter
      include Enumerable

      def initialize(enums_from_aggregations)
        @source_enums = enums_from_aggregations
      end

      def each
        @source_enums.each do |agg|
          agg.each do |rec|
            unless ["renewing_waived", "inactive", "void", "coverage_canceled", "coverage_terminated"].include?(rec["aasm_state"].to_s)
              yield rec["hbx_enrollment_id"]
            end
          end
        end
      end
    end


    class RenewalSimulationEligibleFilter
      include Enumerable

      def initialize(enums_from_aggregations, coverage_start_date)
        @source_enums = enums_from_aggregations
        @coverage_start_date = coverage_start_date
      end

      def each
        @source_enums.each do |agg|
          agg.each do |rec|
            unless ["renewing_waived", "inactive", "void", "coverage_canceled", "coverage_terminated"].include?(rec["aasm_state"].to_s)
              if (rec["_id"]["effective_on"] == @coverage_start_date) 
                yield rec["hbx_enrollment_id"]
              end
            end
          end
        end
      end
    end

    def self.shop_initial_enrollments(organization, effective_on)
      sponsored_benefits = find_ie_sponsored_benefits(organization, effective_on)
      last_chance_to_cancel_at = nil

      queries = sponsored_benefits.map do |sb|
        last_chance_to_cancel_at = initial_sponsored_benefit_last_cancel_chance(sb)
        query_for_initial_sponsored_benefit(sb, effective_on)
      end
      InitialEnrollmentFilter.new(last_chance_to_cancel_at, queries) 
    end

    def self.initial_sponsored_benefit_last_cancel_chance(sb)
      TimeKeeper.end_of_exchange_day_from_utc(sb.benefit_package.open_enrollment_end_on)
    end

    def self.query_for_initial_sponsored_benefit(sb, effective_on)
        sb_id = sb.id
        threshold_time = initial_sponsored_benefit_last_cancel_chance(sb)
        Family.collection.aggregate([
          {
            "$match" => {
              "households.hbx_enrollments.sponsored_benefit_id" => sb_id
            }
          },
          {"$unwind" => "$households"},
          {"$unwind" => "$households.hbx_enrollments"},
          { "$match" => {
            "households.hbx_enrollments.sponsored_benefit_id" => sb_id,
            "households.hbx_enrollments.aasm_state" => {"$in" => new_enrollment_statuses},
            "households.hbx_enrollments.effective_on" => effective_on,
            "households.hbx_enrollments.kind" => {"$in" => ["employer_sponsored", "employer_sponsored_cobra"]},
            "households.hbx_enrollments.submitted_at" => {"$lte" => threshold_time}
          }},
          {"$sort" => {"households.hbx_enrollments.submitted_at" => 1}},
          {
            "$group" => {
              "_id" => {
                "employee_role_id" => "$households.hbx_enrollments.employee_role_id",
                "sponsored_benefit_id" => "$households.hbx_enrollments.sponsored_benefit_id"
              },
              "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments.hbx_id"},
              "aasm_state" => {"$last" => "$households.hbx_enrollments.aasm_state"},
              "submitted_at" => {"$last" => "$households.hbx_enrollments.submitted_at"},
              "workflow_state_transitions" => {"$last" => "$households.hbx_enrollments.workflow_state_transitions"},
              "product_id" => {"$last" => "$households.hbx_enrollments.product_id"}
            }
          }
        ])
    end

    def self.renewal_gate_lifted_enrollments(organization, effective_on, as_of_time = ::TimeKeeper.date_of_record)
      sponsored_benefits = find_renewal_sponsored_benefits(organization, effective_on)
      aggregations = sponsored_benefits.map do |sb|
        find_renewal_transmission_enrollments(sb, as_of_time)
      end
      RenewalTransmissionEligibleFilter.new(aggregations)
    end

    def self.find_simulated_renewal_enrollments(sponsored_benefits, effective_on, as_of_time = ::TimeKeeper.date_of_record)
      aggregations = sponsored_benefits.map do |sb|
        find_renewal_transmission_enrollments(sb, as_of_time + 1.day)
      end
      RenewalSimulationEligibleFilter.new(aggregations, effective_on)
    end

    def self.find_renewal_transmission_enrollments(sb, as_of_time)
      sb_id = sb.id
      Family.collection.aggregate([
        {
          "$match" => {
            "households.hbx_enrollments.sponsored_benefit_id" => sb_id
          }
        },
        {"$unwind" => "$households"},
        {"$unwind" => "$households.hbx_enrollments"},
        { "$match" => {
          "households.hbx_enrollments.sponsored_benefit_id" => sb_id,
          "households.hbx_enrollments.aasm_state" => {"$in" => new_enrollment_statuses},
          "households.hbx_enrollments.kind" => {"$in" => ["employer_sponsored", "employer_sponsored_cobra"]},
          "households.hbx_enrollments.submitted_at" => {"$lte" => as_of_time}
        }},
        {"$sort" => {"households.hbx_enrollments.submitted_at" => 1}},
        {
          "$group" => {
            "_id" => {
              "employee_role_id" => "$households.hbx_enrollments.employee_role_id",
              "sponsored_benefit_id" => "$households.hbx_enrollments.sponsored_benefit_id",
              "effective_on" => "$households.hbx_enrollments.effective_on"
            },
            "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments.hbx_id"},
            "aasm_state" => {"$last" => "$households.hbx_enrollments.aasm_state"},
            "submitted_at" => {"$last" => "$households.hbx_enrollments.submitted_at"},
            "product_id" => {"$last" => "$households.hbx_enrollments.product_id"}
          }
        }
      ])
    end

    def self.find_renewal_sponsored_benefits(organization, effective_on)
      benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(organization.employer_profile).eligible_renewal_applications_on(effective_on)

      benefit_sponsorships.flat_map do |bs|
        bs.benefit_applications.select do |ba|
          (ba.start_on == effective_on) && ["active", "enrollment_eligible"].include?(ba.aasm_state.to_s)
        end
      end.flat_map(&:benefit_packages).flat_map(&:sponsored_benefits)
    end

    def self.find_ie_sponsored_benefits(organization, effective_on)
      benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(organization.employer_profile).may_transmit_initial_enrollment?(effective_on)

      benefit_sponsorships.flat_map do |bs|
        bs.benefit_applications.select do |ba|
          (ba.start_on == effective_on) && ["active", "enrollment_eligible"].include?(ba.aasm_state.to_s)
        end
      end.flat_map(&:benefit_packages).flat_map(&:sponsored_benefits)
    end

    def self.new_enrollment_statuses
      HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::CANCELED_STATUSES + HbxEnrollment::WAIVED_STATUSES
    end
=begin
    def self.all_outstanding_shop
      qs = ::Queries::PolicyAggregationPipeline.new
      qs.filter_to_shop.filter_to_active.with_effective_date({"$gt" => Date.new(2015,1,31)}).eliminate_family_duplicates
      enroll_pol_ids = []
      qs.evaluate.each do |r|
        enroll_pol_ids << r['hbx_id']
      end
      enroll_pol_ids
    end

    def self.can_be_skipped?(hbx_id)
      enrollment = HbxEnrollment.by_hbx_id(hbx_id)[0]
      plan_year = enrollment.benefit_group.plan_year

      # Skip renewal enrollments that're purchased later than quiet period end date from shop monthly query.
      if plan_year.has_renewal_history?
        enrollment.submitted_at > plan_year.enrollment_quiet_period.end
      else
        plan_year.enrollment_quiet_period.cover?(enrollment.submitted_at)
      end
    end

    def self.shop_quiet_period_enrollments(effective_on, enrollment_statuses)
      feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {
        :start_on => effective_on, :aasm_state => 'enrolled'
        }}).pluck(:fein)

      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.enrollment_statuses = enrollment_statuses

      qs.query_families_with_quiet_period_enrollments
        .unwind_enrollments
        .query_quiet_period_enrollments
        .sort_enrollments
        .group_enrollment_events
        .project_enrollment_ids
      qs.evaluate.collect{|r| r['enrollment_hbx_id']}
    end

    def self.shop_monthly_terminations(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.query_families
        .unwind_enrollments
        .query_enrollments
        .sort_enrollments
        .group_enrollments
        .project_enrollment_ids

      qs.evaluate.group_by{|r| r["_id"]["employee_role_id"]}.inject([]) do |termed_enrollments, (subscriber, records)|
        prev_enrollments = records.select{|r| r["_id"]["effective_on"] < effective_on}

        termed_enrollments += prev_enrollments.select do |prev_e|
          records.none? do |r|
            prev_e["_id"]["coverage_kind"] == r["_id"]["coverage_kind"] && r["_id"]["effective_on"] == effective_on 
          end
        end.collect{|record| record['enrollment_hbx_id']}
      end
    end
=end
  end
end
