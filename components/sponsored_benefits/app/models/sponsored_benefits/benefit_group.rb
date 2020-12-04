module SponsoredBenefits
  class BenefitGroup
    include Mongoid::Document
    include Mongoid::Timestamps

    include ::Eligibility::BenefitGroup
    include Config::AcaModelConcern

    embedded_in :benefit_application, class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

    attr_accessor :metal_level_for_elected_plan, :carrier_for_elected_plan

    PLAN_OPTION_KINDS = %w(sole_source single_plan single_carrier metal_level)
    EFFECTIVE_ON_KINDS = %w(date_of_hire first_of_month)
    OFFSET_KINDS = [0, 1, 30, 60]
    PERSONAL_RELATIONSHIP_KINDS = [
      :employee,
      :spouse,
      :domestic_partner,
      :child_under_26,
      :child_26_and_over
    ]

    field :title, type: String, default: ""
    field :description, type: String, default: ""
    field :effective_on_kind, type: String, default: "first_of_month"
    field :terminate_on_kind, type: String, default: "end_of_month"
    field :plan_option_kind, type: String
    field :default, type: Boolean, default: true  # is default benefit group

    field :contribution_pct_as_int, type: Integer, default: 0
    field :employee_max_amt, type: Money, default: 0
    field :first_dependent_max_amt, type: Money, default: 0
    field :over_one_dependents_max_amt, type: Money, default: 0

    # Number of days following date of hire
    field :effective_on_offset, type: Integer, default: 0

    # Non-congressional
    # belongs_to :reference_plan, class_name: "Plan"
    field :reference_plan_id, type: BSON::ObjectId
    field :lowest_cost_plan_id, type: BSON::ObjectId
    field :highest_cost_plan_id, type: BSON::ObjectId


    # Employer contribution amount as percentage of reference plan premium
    field :employer_max_amt_in_cents, type: Integer, default: 0

    # Array of plan_ids
    field :elected_plan_ids, type: Array, default: []
    field :is_congress, type: Boolean, default: false
    field :_type, type: String, default: self.name


    embeds_many :composite_tier_contributions, cascade_callbacks: true
    accepts_nested_attributes_for :composite_tier_contributions, reject_if: :all_blank, allow_destroy: true

    embeds_many :relationship_benefits, cascade_callbacks: true
    accepts_nested_attributes_for :relationship_benefits, reject_if: :all_blank, allow_destroy: true

    embeds_many :dental_relationship_benefits, cascade_callbacks: true
    accepts_nested_attributes_for :dental_relationship_benefits, reject_if: :all_blank, allow_destroy: true


    #TODO add following attributes: :title,
    validates_presence_of :relationship_benefits, :effective_on_kind, :terminate_on_kind, :effective_on_offset,
                          :reference_plan_id, :plan_option_kind, :elected_plan_ids

    validates_uniqueness_of :title

    validates :plan_option_kind,
      allow_blank: false,
      inclusion: {
        in: PLAN_OPTION_KINDS,
        message: "%{value} is not a valid plan option kind"
      }

    validates :effective_on_kind,
      allow_blank: false,
      inclusion: {
        in: EFFECTIVE_ON_KINDS,
        message: "%{value} is not a valid effective date kind"
      }

    validates :effective_on_offset,
      allow_blank: false,
      inclusion: {
        in: OFFSET_KINDS,
        message: "%{value} is not a valid effective date offset kind"
      }

    validate :plan_integrity
    validate :check_employer_contribution_for_employee
    validate :check_offered_for_employee

    before_save :update_dependent_composite_tiers
    before_destroy :delete_benefit_group_assignments_and_enrollments

    # def plan_option_kind=(new_plan_option_kind)
    #   super new_plan_option_kind.to_s
    # end

    alias_method :is_default?, :default
    alias_method :is_congress?, :is_congress


    def benefit_group_assignments
      BenefitGroupAssignment.by_benefit_group_id(id)
    end

    def census_employees
      CensusEmployee.find_all_by_benefit_group(self)
    end

    def employer_profile
      benefit_application.employer_profile
    end

    def sorted_composite_tier_contributions
      self.composite_tier_contributions.sort{|a,b| a.sort_val <=> b.sort_val}
    end

    def reference_plan=(new_reference_plan)
      raise ArgumentError.new("expected Plan") unless new_reference_plan.is_a? Plan
      self.reference_plan_id = new_reference_plan._id
      @reference_plan = new_reference_plan
    end

    def reference_plan
      return @reference_plan if defined? @reference_plan
      @reference_plan = Plan.find(reference_plan_id) unless reference_plan_id.nil?
    end

    def is_open_enrollment?
      benefit_application.open_enrollment.cover?(TimeKeeper.date_of_record)
    end

    def termination_effective_on_for(new_date)
      if benefit_application.open_enrollment_period.cover?(new_date) || new_date < benefit_application.effective_period.begin
        benefit_application.effective_period.begin
      else
        new_date.end_of_month if terminate_on_kind == "end_of_month"
      end
    end

    def set_bounding_cost_plans
      return if reference_plan_id.nil?

      if plan_option_kind == "single_plan"
        plans = [reference_plan]
      elsif plan_option_kind == "sole_source"
        plans = [reference_plan]
      else
        if plan_option_kind == "single_carrier"
          plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile)
        else
          plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level])
        end
      end

      set_lowest_and_highest(plans)
    end

    def set_lowest_and_highest(plans)
      if plans.size > 0
        plans_by_cost = plans.sort_by { |plan| plan.premium_tables.first.cost }

        self.lowest_cost_plan_id  = plans_by_cost.first.id
        @lowest_cost_plan = plans_by_cost.first

        self.highest_cost_plan_id = plans_by_cost.last.id
        @highest_cost_plan = plans_by_cost.last
      end
    end

    def lowest_cost_plan
      return @lowest_cost_plan if defined? @lowest_cost_plan
    end

    def highest_cost_plan
      return @highest_cost_plan if defined? @highest_cost_plan
    end

    def elected_plans=(new_plans)
      return unless new_plans.present?

      if new_plans.is_a? Array
        self.elected_plan_ids = new_plans.reduce([]) { |list, plan| list << plan._id }
      else
        self.elected_plan_ids = Array.new(1, new_plans.try(:_id))
      end

      set_bounding_cost_plans
      @elected_plans = new_plans
    end

    def elected_plans
      return @elected_plans if defined? @elected_plans
      @elected_plans ||= Plan.where(:id => {"$in" => elected_plan_ids}).to_a
    end

    def decorated_elected_plans(member_provider, coverage_kind="")
      max_contribution_cache = Hash.new
      get_elected_plans = (coverage_kind == "health" ? elected_plans : elected_dental_plans)
      ref_plan = (coverage_kind == "health" ? reference_plan : dental_reference_plan)
      get_elected_plans.collect(){|plan| decorated_plan(plan, member_provider, ref_plan, max_contribution_cache)}
    end

    def decorated_plan(plan, member_provider, ref_plan, max_contribution_cache = {})
      if self.sole_source? && (!plan.dental?)
        CompositeRatedPlanCostDecorator.new(plan, self, member_provider.composite_rating_tier, member_provider.is_cobra_status?)
      else
        PlanCostDecorator.new(plan, member_provider, self, ref_plan, max_contribution_cache)
      end
    end

    def effective_composite_tier(ce)
      employer_offered_family_benefits = composite_tier_contributions.find_by(composite_rating_tier: 'family').offered?
      employer_offered_family_benefits ? ce.composite_rating_tier : 'employee_only'
    end

    def assignable_to?(census_employee)
      return !(census_employee.employment_terminated_on < benefit_sponsorship.effective_period.begin || census_employee.hired_on > benefit_sponsorship.effective_period.end)
    end

    def employer_max_amt_in_cents=(new_employer_max_amt_in_cents)
      write_attribute(:employer_max_amt_in_cents, dollars_to_cents(new_employer_max_amt_in_cents))
    end

    def premium_in_dollars
      cents_to_dollars(employer_max_amt_in_cents)
    end

    def relationship_benefit_for(relationship)
      relationship_benefits.where(relationship: relationship).first
    end

    def build_relationship_benefits
      self.relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
         self.relationship_benefits.build(relationship: relationship, offered: true)
      end
    end

    def build_composite_tier_contributions
      self.composite_tier_contributions = CompositeRatingTier::NAMES.map do |rating_tier|
        self.composite_tier_contributions.build(composite_rating_tier: rating_tier, offered: true)
      end
    end

    def build_dental_relationship_benefits
      self.dental_relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
         self.dental_relationship_benefits.build(relationship: relationship, offered: true)
      end
    end

    def simple_benefit_list(employee_premium_pct, dependent_premium_pct, employer_max_amount)
      [
        RelationshipBenefit.new(benefit_group: self,
                                relationship: :employee,
                                premium_pct: employee_premium_pct,
                                employer_max_amt: employer_max_amount,
                                offered: true),
      ] + PERSONAL_RELATIONSHIP_KINDS.dup.delete_if{|kind| [:employee, :child_26_and_over].include?(kind)}.collect do |relationship|
        RelationshipBenefit.new(benefit_group: self,
                                relationship: relationship,
                                premium_pct: dependent_premium_pct,
                                employer_max_amt: employer_max_amount,
                                offered: true)
      end + [
        RelationshipBenefit.new(benefit_group: self,
                                relationship: :child_26_and_over,
                                premium_pct: employee_premium_pct,
                                employer_max_amt: employer_max_amount,
                                offered: false),
      ]
    end

    def self.find(id)
      ::Caches::RequestScopedCache.lookup(:employer_calculation_cache_for_benefit_groups, id) do
        organizations = PlanDesignOrganization.unscoped.where({"plan_design_proposals.profile.benefit_sponsorships.benefit_applications.benefit_groups._id" => id })
        organizations.flat_map(&:plan_design_proposals).lazy.map(&:profile).flat_map(&:benefit_sponsorships).flat_map(&:benefit_applications).flat_map(&:benefit_groups).select do |bg|
          bg.id == id
        end.first
      end
    end

    def monthly_employer_contribution_amount(plan = reference_plan)
      return 0 if targeted_census_employees.count > 100

      if self.sole_source? && self.composite_tier_contributions.empty?
        build_composite_tier_contributions
        estimate_composite_rates
      end
      targeted_census_employees.active.collect do |ce|
        pcd = if self.sole_source? && (!plan.dental?)
          CompositeRatedPlanCostDecorator.new(plan, self, effective_composite_tier(ce), ce.is_cobra_status?)
        else
          PlanCostDecorator.new(plan, ce, self, reference_plan)
        end
        pcd.total_employer_contribution
      end.sum
    end

    def monthly_employee_cost(coverage_kind=nil)
      rp = coverage_kind == "dental" ? dental_reference_plan : reference_plan
      return 0 if targeted_census_employees.count > 100
      targeted_census_employees.active.collect do |ce|
        pcd = if self.sole_source? && (!rp.dental?)
          CompositeRatedPlanCostDecorator.new(rp, self, effective_composite_tier(ce), ce.is_cobra_status?)
        else
          PlanCostDecorator.new(rp, ce, self, rp)
        end
        pcd.total_employee_cost
      end
    end

    def monthly_min_employee_cost(coverage_kind = nil)
      monthly_employee_cost(coverage_kind).min
    end

    def monthly_max_employee_cost(coverage_kind = nil)
      monthly_employee_cost(coverage_kind).max
    end

    def targeted_census_employees
      target_object = persisted? ? self : benefit_application.benefit_sponsorship
      target_object.census_employees
    end

    def employee_cost_for_plan(ce, plan = reference_plan)
      pcd = if @is_congress
        decorated_plan(plan, ce)
      elsif plan_option_kind == 'sole_source' && !plan.dental?
        CompositeRatedPlanCostDecorator.new(reference_plan, self, effective_composite_tier(ce), ce.is_cobra_status?)
      else
        PlanCostDecorator.new(plan, ce, self, reference_plan)
      end
      pcd.total_employee_cost
    end

    def single_plan_type?
      plan_option_kind == "single_plan"
    end

    def elected_plans_by_option_kind
      start_on = benefit_application.effective_period.begin
      @profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, benefit_application.effective_period.begin.year)

      case plan_option_kind
      when "sole_source"
        Plan.where(id: reference_plan_id).first
      when "single_plan"
        Plan.where(id: reference_plan_id).first
      when "single_carrier"
        if carrier_for_elected_plan.blank?
          @carrier_for_elected_plan = reference_plan.carrier_profile_id if reference_plan.present?
        end
        carrier_profile_id = reference_plan.carrier_profile_id
        plans = Plan.check_plan_offerings_for_single_carrier # filter by vertical choice(as there should be no bronze plans for one carrier.)
        plans.valid_shop_health_plans_for_service_area("carrier", carrier_for_elected_plan, start_on.year, @profile_and_service_area_pairs.select { |pair| pair.first == carrier_profile_id }).to_a
      when "metal_level"
        Plan.valid_shop_health_plans_for_service_area("carrier", carrier_for_elected_plan, start_on.year, @profile_and_service_area_pairs).and(:metal_level => reference_plan.metal_level).to_a
      end
    end

    def effective_title_by_offset
      case effective_on_offset
      when 0
        "First of the month following or coinciding with date of hire"
      when 1
        "First of the month following date of hire"
      when 30
        "First of the month following 30 days"
      when 60
        "First of the month following 60 days"
      end
    end

    def delete_benefit_group_assignments_and_enrollments # Also assigns default benefit group assignment
      census_employees.each do |ce|
        benefit_group_assignments = ce.benefit_group_assignments.where(benefit_group_id: self.id)

        if benefit_group_assignments.present?
          benefit_group_assignments.each do |bga|
            bga.hbx_enrollments.each { |enrollment| enrollment.destroy }
            bga.destroy
          end

          benefit_groups = self.benefit_application.benefit_groups.select { |bg| bg.id != self.id}
          ce.create_benefit_group_assignment(benefit_groups.first)
        end
      end
    end

    # Interface for composite and list bill.
    # Defines the methods needed for calculation of both composite and list
    # bill values.

    # Provide the sic factor for this benefit group.
    def sic_factor_for(plan)
      if use_simple_employer_calculation_model?
        return 1.0
      end
      factor_carrier_id = plan.carrier_profile_id
      @scff_cache ||= Hash.new do |h, k|
        h[k] = lookup_cached_scf_for(k)
      end
      @scff_cache[factor_carrier_id]
    end

    def lookup_cached_scf_for(carrier_id)
      year = benefit_application.effective_period.begin.year
      SicCodeRatingFactorSet.value_for(carrier_id, year, benefit_application.recorded_sic_code)
    end

    # Provide the base factor for this composite rating tier.
    def composite_rating_tier_factor_for(composite_rating_tier, plan)
      factor_carrier_id = plan.carrier_profile_id
      lookup_key = [factor_carrier_id, composite_rating_tier]
      @crtbf_cache ||= Hash.new do |h, k|
        h[k] = lookup_cached_crtbf_for(k)
      end
      @crtbf_cache[lookup_key]
    end

    def lookup_cached_crtbf_for(carrier_tier_pair)
      year = benefit_application.effective_period.begin.year
      CompositeRatingTierFactorSet.value_for(carrier_tier_pair.first, year, carrier_tier_pair.last)
    end

    # Provide the rating area value for this benefit group.
    def rating_area
      @rating_area ||= benefit_application.recorded_rating_area
    end

    # Provide the participation rate factor for this group.
    def composite_participation_rate_factor_for(plan)
      factor_carrier_id = plan.carrier_profile_id
      @cprf_cache ||= Hash.new do |h, k|
        h[k] = lookup_cached_cprf_for(k)
      end
      @cprf_cache[factor_carrier_id]
    end

    def lookup_cached_cprf_for(carrier_id)
      year = benefit_application.effective_period.begin.year
      EmployerParticipationRateRatingFactorSet.value_for(carrier_id, year, participation_rate * 100.0)
    end

    def participation_rate
      total_employees = targeted_census_employees.count
      return(0.0) if total_employees < 1
      waived_and_active_count = if benefit_application.estimate_group_size?
                                  targeted_census_employees.select { |ce| ce.expected_to_enroll_or_valid_waive? }.length
                                else
                                  all_active_and_waived_health_enrollments.length
                                end
      waived_and_active_count/(total_employees * 1.0)
    end

    # Provide the group size factor for this benefit group.
    def group_size_factor_for(plan)
      if use_simple_employer_calculation_model?
        return 1.0
      end
      factor_carrier_id = plan.carrier_profile_id
      @gsf_cache ||= Hash.new do |h, k|
        h[k] = lookup_cached_gsf_for(k)
      end
      @gsf_cache[factor_carrier_id]
    end

    def lookup_cached_gsf_for(carrier_id)
      year = benefit_application.effective_period.begin.year
      if plan_option_kind == "sole_source"
        EmployerGroupSizeRatingFactorSet.value_for(carrier_id, year, group_size_count)
      else
        EmployerGroupSizeRatingFactorSet.value_for(carrier_id, year, 1)
      end
    end

    # Provide the premium for a given composite rating tier.
    def composite_rating_tier_premium_for(composite_rating_tier)
      @crtp_cache ||= Hash.new do |h, k|
        h[k] = lookup_cached_crtp_for(k)
      end
      @crtp_cache[composite_rating_tier]
    end

                        def lookup_cached_crtp_for(composite_rating_tier)
                          ct_contribution = composite_tier_contributions.detect { |ctc| ctc.composite_rating_tier == composite_rating_tier }
                          benefit_application.estimate_group_size? ? ct_contribution.estimated_tier_premium : ct_contribution.final_tier_premium
                        end

    # Provide the contribution factor for a given composite rating tier.
    def composite_employer_contribution_factor_for(composite_rating_tier)
      @cecf_cache ||= Hash.new do |h, k|
         h[k] = lookup_cached_eccf_for(k)
      end
      @cecf_cache[composite_rating_tier]
    end

    def lookup_cached_eccf_for(composite_rating_tier)
      ct_contribution = composite_tier_contributions.detect { |ctc| ctc.composite_rating_tier == composite_rating_tier }
      ct_contribution.contribution_factor
    end

    # Count of enrolled employees - either estimated or actual depending on plan
    # year status
    def group_size_count
      if benefit_application.estimate_group_size?
        targeted_census_employees.select { |ce| ce.expected_to_enroll? }.length
      else
        all_active_health_enrollments.length
      end
    end

    def composite_rating_enrollment_objects
      if benefit_application.estimate_group_size?
        targeted_census_employees.select { |ce| ce.expected_to_enroll? }
      else
        all_active_health_enrollments
      end
    end

    def all_active_and_waived_health_enrollments
      benefit_group_assignments.flat_map do |bga|
        bga.active_and_waived_enrollments.reject do |en|
          en.dental?
        end
      end
    end

    def all_active_health_enrollments
      benefit_group_assignments.flat_map do |bga|
        bga.active_enrollments.reject do |en|
          en.dental?
        end
      end
    end

    def sole_source?
      plan_option_kind == "sole_source"
    end

    def build_estimated_composite_rates
      return(nil) unless sole_source?
      rate_calc = CompositeRatingBaseRatesCalculator.new(self, self.elected_plans.try(:first) || reference_plan)
      rate_calc.build_estimated_premiums
    end

    def estimate_composite_rates
      return(nil) unless sole_source?
      rate_calc = CompositeRatingBaseRatesCalculator.new(self, self.elected_plans.try(:first) || reference_plan)
      rate_calc.assign_estimated_premiums
    end

    def finalize_composite_rates
      return(nil) unless sole_source?
      rate_calc = CompositeRatingBaseRatesCalculator.new(self, self.elected_plans.first)
      rate_calc.assign_final_premiums
    end

    private

    def update_dependent_composite_tiers
      family_tier = self.composite_tier_contributions.where(composite_rating_tier: 'family')
      return unless family_tier.present?

      # Comment out for BGT
      # return if benefit_application.is_conversion

      contribution = family_tier.first.employer_contribution_percent
      estimated_tier_premium = family_tier.first.estimated_tier_premium
      offered = family_tier.first.offered

      (CompositeRatingTier::NAMES - CompositeRatingTier::VISIBLE_NAMES).each do |crt|
        tier = self.composite_tier_contributions.find_or_initialize_by(
          composite_rating_tier: crt
        )
        tier.employer_contribution_percent = contribution
        tier.offered = offered
      end
    end

    def dollars_to_cents(amount_in_dollars)
      Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
    end

    def cents_to_dollars(amount_in_cents)
      (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
    end

    def is_eligible_to_enroll_on?(date_of_hire, enrollment_date = TimeKeeper.date_of_record)

      # Length of time prior to effective date that EE may purchase plan
      Settings.aca.shop_market.earliest_enroll_prior_to_effective_on.days

      # Length of time following effective date that EE may purchase plan
      Settings.aca.shop_market.latest_enroll_after_effective_on.days

      # Length of time that EE may enroll following correction to Census Employee Identifying info
      Settings.aca.shop_market.latest_enroll_after_employee_roster_correction_on.days

    end

    # Non-congressional
    # pick reference plan
    # two pctages
    # toward employee
    # toward each dependent type

    # member level premium in reference plan, apply pctage by type, calc $$ amount.
    # may be applied toward and other offered plan
    # never pay more than premium per person
    # extra may not be applied toward other members

    def plan_integrity
      return if elected_plan_ids.blank?

      if (plan_option_kind == "single_plan") && (elected_plan_ids.first != reference_plan_id)
        self.errors.add(:elected_plans, "single plan must be the reference plan")
      end

      if (plan_option_kind == "single_carrier")
        if !(elected_plan_ids.include? reference_plan_id)
          self.errors.add(:elected_plans, "single carrier must include reference plan")
        end
        if elected_plans.detect { |plan| plan.carrier_profile_id != reference_plan.try(:carrier_profile_id) }
          self.errors.add(:elected_plans, "not all from the same carrier as reference plan")
        end
      end

      if (plan_option_kind == "metal_level") && !(elected_plan_ids.include? reference_plan_id)
        self.errors.add(:elected_plans, "not all of the same metal level as reference plan")
      end
    end

    def check_employer_contribution_for_employee
      start_on = benefit_application.effective_period.try(:begin)
      return if start_on.try(:at_beginning_of_year) == start_on

      # all employee contribution < 50% for 1/1 employers
      if start_on.month == 1 && start_on.day == 1
      else
        if self.sole_source?
          unless composite_tier_contributions.present?
            self.errors.add(:composite_rating_tier, "Employer must set contribution percentages")
          else
            employee_tier = composite_tier_contributions.find_by(composite_rating_tier: 'employee_only')

            if aca_shop_market_employer_contribution_percent_minimum > (employee_tier.try(:employer_contribution_percent) || 0)
              self.errors.add(:composite_tier_contributions,
              "Employer contribution for employee must be ≥ #{aca_shop_market_employer_contribution_percent_minimum}%")
            else
              family_tier = composite_tier_contributions.find_by(composite_rating_tier: 'family')
              if family_tier.offered? &&
                (family_tier.try(:employer_contribution_percent) || 0) < aca_shop_market_employer_family_contribution_percent_minimum
                  self.errors.add(:composite_tier_contributions, "Employer contribution for family plans must be ≥ #{aca_shop_market_employer_family_contribution_percent_minimum}")
              end
            end
          end
        else
          if relationship_benefits.present? && (relationship_benefits.find_by(relationship: "employee").try(:premium_pct) || 0) < aca_shop_market_employer_contribution_percent_minimum
            self.errors.add(:relationship_benefits, "Employer contribution must be ≥ #{aca_shop_market_employer_contribution_percent_minimum}% for employee")
          end
        end
      end
    end

    def check_offered_for_employee
      if relationship_benefits.present? && (relationship_benefits.find_by(relationship: "employee").try(:offered) != true)
        self.errors.add(:relationship_benefits, "employee must be offered")
      end
    end

  end
end
