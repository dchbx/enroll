# frozen_string_literal: true

class BenefitPackage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_coverage_period

  BENEFIT_BEGIN_AFTER_EVENT_OFFSET_KINDS = [0, 30, 60, 90].freeze
  BENEFIT_EFFECTIVE_DATE_KINDS      = %w[date_of_event first_of_month].freeze
  BENEFIT_TERMINATION_DATE_KINDS    = %w[date_of_event end_of_month].freeze


  PREMIUM_CREDIT_STRATEGY_KINDS = %w[unassisted employer_fixed_cost employee_fixed_cost allocated_lump_sum_credit
                                     percentage_contribution indexed_percentage_contribution federal_employee_health_benefit].freeze


  field :title, type: String, default: ""

  field :benefit_begin_after_event_offsets, type: Array, default: []
  field :benefit_effective_dates,           type: Array, default: []
  field :benefit_termination_dates,         type: Array, default: []

  field :elected_premium_credit_strategy,   type: String
  field :index_benefit_id,                  type: BSON::ObjectId
  field :benefit_ids,                       type: Array, default: []

  delegate :start_on, :end_on, to: :benefit_coverage_period

  delegate :market_places, :enrollment_periods, :family_relationships, :benefit_categories,
           :incarceration_status, :age_range, :citizenship_status, :residency_status, :ethnicity, :cost_sharing,
           to: :benefit_eligibility_element_group

  delegate :market_places=, :enrollment_periods=, :family_relationships=, :benefit_categories=,
           :incarceration_status=, :age_range=, :citizenship_status=, :residency_status=, :ethnicity=,
           to: :benefit_eligibility_element_group


  embeds_one :benefit_eligibility_element_group
  accepts_nested_attributes_for :benefit_eligibility_element_group

  after_initialize :initialize_dependent_models

  def initialize_dependent_models
    build_benefit_eligibility_element_group if benefit_eligibility_element_group.nil?
  end

  def effective_year
    start_on.year
  end


end
