class QuoteBenefitGroup
  include Mongoid::Document
  include MongoidSupport::AssociationProxies

  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over
  ]

  embedded_in :quote

  field :title, type: String
  field :default, type: Boolean, default: false

  field :plan_option_kind, type: String, default: "single_carrier"
  field :dental_plan_option_kind, type: String, default: "single_carrier"

  field :contribution_pct_as_int, type: Integer, default: 0
  field :employee_max_amt, type: Money, default: 0
  field :first_dependent_max_amt, type: Money, default: 0
  field :over_one_dependents_max_amt, type: Money, default: 0


  field :reference_plan_id, type: BSON::ObjectId
  field :lowest_cost_plan_id, type: BSON::ObjectId
  field :highest_cost_plan_id, type: BSON::ObjectId
  field :dental_reference_plan_id, type: BSON::ObjectId

  field :published_reference_plan, type: BSON::ObjectId
  field :published_lowest_cost_plan, type: BSON::ObjectId
  field :published_highest_cost_plan, type: BSON::ObjectId
  field :published_dental_reference_plan, type: BSON::ObjectId

  associated_with_one :plan, :published_reference_plan, "Plan"
  associated_with_one :lowest_cost_plan, :published_lowest_cost_plan, "Plan"
  associated_with_one :highest_cost_plan, :published_highest_cost_plan, "Plan"
  associated_with_one :dental_plan, :published_dental_reference_plan, "Plan"

  embeds_many :quote_relationship_benefits, cascade_callbacks: true
  embeds_many :quote_dental_relationship_benefits, cascade_callbacks: true

  field :criteria_for_ui, type: String, default: []
  field :deductible_for_ui, type: String, default: 6000
  field :dental_criteria_for_ui, type: String, default: []

  delegate :start_on, to: :quote
  delegate :quote_name, to: :quote
  delegate :aasm_state, to: :quote


  validates_presence_of :title

  before_save :build_relationship_benefits
  before_save :build_dental_relationship_benefits


  def quote_households
    quote.quote_households.select{|hh| hh.quote_benefit_group_id == self.id}
  end

  def relationship_benefit_for(relationship)
    quote_relationship_benefits.where(relationship: relationship).first
  end

  def dental_relationship_benefit_for(relationship)
    quote_dental_relationship_benefits.where(relationship: relationship).first
  end

  def build_relationship_benefits
    return if self.quote_relationship_benefits.present?

    self.quote_relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|

      # 'employee' relationship should be set to a min of 50%
      initial_premium_pct = relationship.to_s == "employee" ? 50 : 0
       self.quote_relationship_benefits.build(relationship: relationship, offered: true, premium_pct: initial_premium_pct)
    end
  end

  def build_dental_relationship_benefits
    return if self.quote_dental_relationship_benefits.present?

    self.quote_dental_relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
       self.quote_dental_relationship_benefits.build(relationship: relationship, offered: true)
    end
  end

  def reference_plan=(new_reference_plan)
    raise ArgumentError.new("expected Plan") unless new_reference_plan.is_a? Plan
    self.reference_plan_id = new_reference_plan._id
  end

  def reference_plan
    return @reference_plan if defined? @reference_plan
    @reference_plan = Plan.find(reference_plan_id) unless reference_plan_id.nil?
  end

  def set_bounding_cost_plans
    return if reference_plan_id.nil?
    if quote.plan_option_kind == "single_plan"
      plans = [reference_plan]
    else
      if quote.plan_option_kind == "single_carrier"
        plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile)
      else
        plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level])
      end
    end

    if plans.size > 0
      plans_by_cost = plans.sort_by { |plan| plan.premium_tables.first.cost }

      self.lowest_cost_plan_id  = plans_by_cost.first.id
      self.highest_cost_plan_id = plans_by_cost.last.id
    end
  end


  def roster_employee_cost(plan_id, reference_plan_id)
    p = Plan.find(plan_id)
    reference_plan = Plan.find(reference_plan_id)
    cost = 0
    quote.quote_households.each do |hh|
      pcd = PlanCostDecorator.new(p, hh, self, reference_plan)
      cost = cost + pcd.total_employee_cost.round(2)
    end
    cost.round(2)
  end

  def roster_cost_all_plans(quote_type = 'health')
    @plan_costs= {}
    combined_family = flat_roster_for_premiums
    quote_collection = quote_type == 'health' ? $quote_shop_health_plans : $quote_shop_dental_plans
    quote_collection.each {|plan|
      @plan_costs[plan.id.to_s] = roster_premium(plan, combined_family)
    }
    @plan_costs
  end

  def roster_premium(plan, combined_family)
    roster_premium = Hash.new{|h,k| h[k]=0.00}
    pcd = PlanCostDecoratorQuote.new(plan, nil, self, plan)
    reference_date = pcd.plan_year_start_on
    pcd.add_premiums(combined_family, reference_date)

  end

  def flat_roster_for_premiums
    p = $quote_shop_health_plans[0]  #any plan
    combined_family = Hash.new{|h,k| h[k] = 0}
    self.quote_households.each do |hh|
      pcd = PlanCostDecoratorQuote.new(p, hh, self, p)
      pcd.add_members(combined_family)
    end
    combined_family
  end

  def roster_employer_contribution(plan_id, reference_plan_id)
    p = Plan.find(plan_id)
    reference_plan = Plan.find(reference_plan_id)
    cost = 0
    self.quote_households.each do |hh|
      pcd = PlanCostDecorator.new(p, hh, self, reference_plan)
      cost = cost + pcd.total_employer_contribution.round(2)
    end
    cost.round(2)
  end


  def cost_by_offerings(plan)
    plan_costs_by_offerings = Hash.new
    PLAN_OPTION_KINDS.map { |offering| plan_costs_by_offerings[offering] = bounding_cost_plans(plan, offering.to_s) }
    plan_costs_by_offerings.merge({"reference_plan_cost" => roster_employer_contribution(plan.id, plan.id)})
  end

  def plan_by_offerings(reference_plan, plan_option_kind)
    if plan_option_kind == "single_plan" || plan_option_kind == "Single Plan"
      plans = [reference_plan]
    else
      if plan_option_kind == "single_carrier" || plan_option_kind == "Single Carrier"
        plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile)
      else
        plans = Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level])
      end
    end
  end

  def cost_for_plans(plans, reference_plan)
    cost = plans.map { |p| {"plan_name" => p.name, "metal_level"=> p.metal_level, "plan_id" => p.id.to_s, "employer_cost" => roster_employer_contribution(p.id,reference_plan), "employee_cost" => roster_employee_cost(p.id,reference_plan)}}
  end

  def bounding_cost_plans (reference_plan, plan_option_kind)

    plans = plan_by_offerings(reference_plan, plan_option_kind)

      if plans.size > 0
        plans_by_cost = plans.sort_by { |plan| plan.premium_tables.first.cost }
        {"lowest_cost_plan_cost" => roster_employer_contribution(plans_by_cost.first.id, reference_plan.id), "highest_cost_plan_cost" => roster_employer_contribution(plans_by_cost.last.id, reference_plan.id)}
      else
        {}
      end
  end

  def published_employer_cost
    plan && roster_employer_contribution(plan.id, plan.id)
  end

  # Determines if this benefit group is assigned to a quote household
  def is_assigned?
    self.quote.quote_households.each do |quote_household|
      return true if self.id == quote_household.quote_benefit_group_id
    end
    return false
  end

  class << self

    def find(id)
      quotes = Quote.where("quote_benefit_groups._id" => BSON::ObjectId.from_string(id))
      quotes.size > 0 ? quotes.first.quote_benefit_groups.where("_id" => BSON::ObjectId.from_string(id)).first : nil
    rescue
      log("Can not find quote benefit group with id #{id}", {:severity => "error"})
      nil
    end
  end

end
