module Queries
  class ShopMonthlyEnrollments
    include QueryHelpers

    attr_accessor :enrollment_statuses

    def initialize(feins, effective_on)
      @feins = feins
      @effective_on = effective_on
      @pipeline = []
    end

    def add(step)
      @pipeline << step.to_hash
    end

    def evaluate
      Family.collection.aggregate(@pipeline)
    end

    def query_families_with_quiet_period_enrollments
      add({
        "$match" => {
          "$and" => [
            "households.hbx_enrollments.benefit_group_id" => { "$in" => collect_benefit_group_ids },
            "households.hbx_enrollments.workflow_state_transitions" => { "$elemMatch" => quiet_period_expression }
          ]
        }
      })

      self
    end

    def query_families_with_active_enrollments
       add({
        "$match" => {
          "households.hbx_enrollments.benefit_group_id" => {
            "$in" => collect_benefit_group_ids
          }
        }
      })

      self
    end

     def query_active_enrollments
      add({
        "$match" => {
          "$or" => [
            new_coverage_expression
          ]
        }
      })

      self
    end

    def query_quiet_period_enrollments
      add({
        "$match" => {
          "$or" => [
            quiet_period_coverage_expression
          ]
        }
      })

      self
    end

    def query_families
      add({
        "$match" => {
          "households.hbx_enrollments.benefit_group_id" => {
            "$in" => (collect_benefit_group_ids + collect_benefit_group_ids(@effective_on.prev_year))
          }
        }
      })

      self
    end

    def unwind_enrollments
      add({"$unwind" => "$households"})
      add({"$unwind" => "$households.hbx_enrollments"})
      self
    end

    def new_enrollment_statuses
      HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES
    end

    def existing_enrollment_statuses
      HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + ['coverage_expired']
    end

    def quiet_period
      prev_month = @effective_on.prev_month
      quiet_period_begin = Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on + 1)
      quiet_period_end = Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.initial_application.quiet_period_end_on)
      TimeKeeper.start_of_exchange_day_from_utc(quiet_period_begin)..TimeKeeper.end_of_exchange_day_from_utc(quiet_period_end)
    end

    def quiet_period_expression
      {
        "to_state" => {"$in" => @enrollment_statuses},
        "transition_at" => { 
          "$gte" => quiet_period.begin, 
          "$lt" => quiet_period.end
        }
      }
    end

    def quiet_period_coverage_expression
      {
        "households.hbx_enrollments.benefit_group_id" => { "$in" => collect_benefit_group_ids },
        "households.hbx_enrollments.kind" => "employer_sponsored",
        "households.hbx_enrollments.workflow_state_transitions" => { 
          "$elemMatch" => quiet_period_expression 
        }
      }
    end

    def new_coverage_expression
      {
        "households.hbx_enrollments.benefit_group_id" => {"$in" => collect_benefit_group_ids},
        "households.hbx_enrollments.aasm_state" => {"$in" => new_enrollment_statuses},
        "households.hbx_enrollments.effective_on" => @effective_on,
        # Exclude COBRA, for now
        "households.hbx_enrollments.kind" => {"$in" => ["employer_sponsored", "employer_sponsored_cobra"]}
      }
    end

    def existing_coverage_expression
      {
        "households.hbx_enrollments.benefit_group_id" => {"$in" => collect_benefit_group_ids(@effective_on.prev_year)},
        "households.hbx_enrollments.aasm_state" => {"$in" => existing_enrollment_statuses},
        "households.hbx_enrollments.effective_on" => {"$gte" => @effective_on.prev_year},
        # Exclude COBRA, for now
        "households.hbx_enrollments.kind" => "employer_sponsored"
      }
    end

    def query_enrollments
      add({
        "$match" => {
          "$or" => [
            new_coverage_expression.merge!("households.hbx_enrollments.enrollment_kind" => "open_enrollment"),
            existing_coverage_expression
          ]
        }
      })

      self
    end

    def group_enrollments
      add({
        "$group" => {
          "_id" => {
            "effective_on" => "$households.hbx_enrollments.effective_on",
            "employee_role_id" => "$households.hbx_enrollments.employee_role_id",
            "bga_id" => "$households.hbx_enrollments.benefit_group_assignment_id",
            "coverage_kind" => "$households.hbx_enrollments.coverage_kind"
          },
          "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments.hbx_id"},
          "submitted_at" => {"$last" => "$households.hbx_enrollments.submitted_at"}
        }
      })

      self
    end

    def group_enrollment_events
      add({
        "$group" => {
          "_id" => "$households.hbx_enrollments.hbx_id",
          "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments.hbx_id"},
          "submitted_at" => {"$last" => "$households.hbx_enrollments.submitted_at"}
        }
      })

      self
    end

    def sort_enrollments
      add({
       "$sort" => {"households.hbx_enrollments.submitted_at" => 1}
      })
      self
    end

    def project_enrollment_ids
      add({
        "$project" => {
         "_id" => 1,
         "enrollment_hbx_id" => "$hbx_enrollment_id",
         "enrollment_submitted_at" => "$submitted_at"
        }
      })
      self
    end

    def collect_benefit_group_ids(effective_on = nil)
      @feins.collect{|e| prepend_zeros(e.to_s, 9) }.inject([]) do |id_list, fein|
        employer = EmployerProfile.find_by_fein(fein)
        if employer.present?
          plan_years = employer.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE + ['expired'])
          plan_year = plan_years.where(:start_on => effective_on || @effective_on).first
        end

        if plan_year.blank? || plan_year.external_plan_year?
          id_list
        else
          id_list += plan_year.benefit_groups.map(&:id)
        end
      end
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end
