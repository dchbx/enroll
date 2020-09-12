# frozen_string_literal: true

# rubocop:disable all

class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  COVERAGE_KINDS = %w[health dental].freeze
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental].freeze
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum dental].freeze
  MARKET_KINDS = %w[shop individual].freeze
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo].freeze
  DENTAL_METAL_LEVEL_KINDS = %w[high low].freeze


  field :hbx_id, type: Integer
  field :active_year, type: Integer
  field :market, type: String
  field :coverage_kind, type: String
  field :carrier_profile_id, type: BSON::ObjectId
  field :metal_level, type: String
  field :service_area_id, type: String
  field :hios_id, type: String
  field :hios_base_id, type: String
  field :csr_variant_id, type: String

  field :name, type: String
  field :abbrev, type: String
  field :provider, type: String
  field :ehb, type: Float, default: 0.0

  field :renewal_plan_id, type: BSON::ObjectId
  field :cat_age_off_renewal_plan_id, type: BSON::ObjectId
  field :is_standard_plan, type: Boolean, default: false

  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String

  # TODO: deprecate after migrating SBCs for years prior to 2016
  field :sbc_file, type: String
  embeds_one :sbc_document, :class_name => "Document", as: :documentable

  embeds_many :premium_tables
  accepts_nested_attributes_for :premium_tables, :sbc_document

  # More Attributes from qhp
  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :deductible, type: String # Deductible
  field :family_deductible, type: String

  field :nationwide, type: Boolean # Nationwide
  field :dc_in_network, type: Boolean # DC In-Network or not

  # Fields for provider direcotry and rx formulary url
  field :provider_directory_url, type: String
  field :rx_formulary_url, type: String

  # for dental plans only, metal level -> high/low values
  field :dental_level, type: String

  field :is_horizontal, type: Boolean, default: -> { true }
  field :is_vertical, type: Boolean, default: -> { true }
  field :is_sole_source, type: Boolean, default: -> { true }

  default_scope -> {order("name ASC")}

  # Metal level
  scope :platinum_level,      ->{ where(metal_level: "platinum") }
  scope :gold_level,          ->{ where(metal_level: "gold") }
  scope :silver_level,        ->{ where(metal_level: "silver") }
  scope :bronze_level,        ->{ where(metal_level: "bronze") }
  scope :catastrophic_level,  ->{ where(metal_level: "catastrophic") }


  scope :metal_level_sans_silver,  ->{ where(:metal_leval.in => %w[platinum gold bronze catastrophic])}

  # Plan.metal_level_sans_silver.silver_level_by_csr_kind("csr_87")
  scope :silver_level_by_csr_kind, lambda { |csr_kind = 'csr_0'|
                                     where(
                                       metal_level: "silver"
                                     ).and(
                                       csr_variant_id: EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]
                                     )
                                   }

  # Plan Type
  scope :ppo_plan, ->{ where(plan_type: "ppo") }
  scope :pos_plan, ->{ where(plan_type: "pos") }
  scope :hmo_plan, ->{ where(plan_type: "hmo") }
  scope :epo_plan, ->{ where(plan_type: "epo") }

  # Plan offers local or national in-network benefits
  # scope :national_network,  ->{ where(nationwide: "true") }
  # scope :local_network,     ->{ where(nationwide: "false") }

  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :ehb, type: Float, default: 0.0

  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :deductible, type: String # Deductible
  field :family_deductible, type: String

  scope :by_active_year,        ->(active_year = TimeKeeper.date_of_record.year) { where(active_year: active_year) }
  scope :by_metal_level,        ->(metal_level) { where(metal_level: metal_level) }
  scope :by_dental_level,       ->(dental_level) { where(dental_level: dental_level) }
  scope :by_plan_type,          ->(plan_type) { where(plan_type: plan_type) }
  scope :by_dental_level_for_bqt,       ->(dental_level) { where(:dental_level.in => dental_level) }
  scope :by_plan_type_for_bqt,          ->(plan_type) { where(:plan_type.in => plan_type) }


  # Marketplace
  scope :shop_market,           ->{ where(market: "shop") }
  scope :individual_market,     ->{ where(market: "individual") }

  scope :health_coverage,       ->{ where(coverage_kind: "health") }
  scope :dental_coverage,       ->{ where(coverage_kind: "dental") }

  # DEPRECATED - 2015-09-23 - By Sean Carley
    # scope :valid_shop_by_carrier, ->(carrier_profile_id) {where(carrier_profile_id: carrier_profile_id, active_year: TimeKeeper.date_of_record.year, market: "shop",  metal_level: {"$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS})}
    # scope :valid_shop_by_metal_level, ->(metal_level) {where(active_year: TimeKeeper.date_of_record.year, market: "shop", metal_level: metal_level)}
  scope :valid_shop_by_carrier, ->(carrier_profile_id) {valid_shop_by_carrier_and_year(carrier_profile_id, TimeKeeper.date_of_record.year)}
  scope :valid_shop_by_metal_level, ->(metal_level) {valid_shop_by_metal_level_and_year(metal_level, TimeKeeper.date_of_record.year)}

  ## DEPRECATED - 2015-10-26 - By Dan Thomas - Use: individual_health_by_active_year_and_csr_kind
  scope :individual_health_by_active_year, ->(active_year) {where(active_year: active_year, market: "individual", coverage_kind: "health", hios_id: /-01$/) }
  # END DEPRECATED

  scope :valid_shop_by_carrier_and_year, lambda { |carrier_profile_id, year|
    where(
      carrier_profile_id: carrier_profile_id,
      active_year: year,
      market: "shop",
      hios_id: { "$not" => /-00$/ },
      metal_level: { "$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS }
    )
  }
  scope :valid_shop_by_metal_level_and_year, lambda { |metal_level, year|
    where(
      active_year: year,
      market: "shop",
      hios_id: /-01$/,
      metal_level: metal_level
    )
  }

  scope :with_premium_tables, ->{ where(:premium_tables.exists => true) }


  scope :shop_health_by_active_year, lambda { |active_year|
                                       where(
                                         active_year: active_year,
                                         market: "shop",
                                         coverage_kind: "health"
                                       )
                                     }

  scope :shop_dental_by_active_year, lambda { |active_year|
                                       where(
                                         active_year: active_year,
                                         market: "shop",
                                         coverage_kind: "dental"
                                       )
                                     }

  scope :individual_health_by_active_year_and_csr_kind, lambda { |active_year, csr_kind = 'csr_0'|
                                                          where(
                                                            "$and" => [
                                                                {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
                                                                {"$or" => [
                                                                            {:metal_level.in => %w[platinum gold bronze], :csr_variant_id => "01"},
                                                                            {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                                                                          ]}
                                                              ]
                                                          )
                                                        }

  scope :individual_health_by_active_year_and_csr_kind_with_catastrophic, lambda { |active_year, csr_kind = 'csr_0'|
                                                                            where(
                                                                              "$and" => [
                                                                                  {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
                                                                                  {"$or" => [
                                                                                              {:metal_level.in => %w[platinum gold bronze catastrophic], :csr_variant_id => "01"},
                                                                                              {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                                                                                            ]}
                                                                                ]
                                                                            )
                                                                          }

  scope :individual_dental_by_active_year, lambda { |active_year|
                                             where(
                                               active_year: active_year,
                                               market: "individual",
                                               coverage_kind: "dental"
                                             )
                                           }

  scope :individual_health_by_active_year_carrier_profile_csr_kind, lambda { |active_year, carrier_profile_id, csr_kind|
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health", :carrier_profile_id => carrier_profile_id },
          {"$or" => [
                      {:metal_level.in => %w[platinum gold bronze], :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]}
        ]
    )
  }

  scope :by_health_metal_levels,                ->(metal_levels)    { any_in(metal_level: metal_levels) }
  scope :by_carrier_profile,                    ->(carrier_profile_id) { where(carrier_profile_id: carrier_profile_id) }
  scope :by_carrier_profile_for_bqt,            ->(carrier_profile_id) { where(:carrier_profile_id.in => carrier_profile_id) }

  scope :health_metal_levels_all,               ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS << "catastrophic") }
  scope :health_metal_levels_sans_catastrophic, ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS) }
  scope :health_metal_nin_catastropic,          ->{ not_in(metal_level: "catastrophic") }
  scope :with_enabled_metal_levels,             -> { any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS)}


  scope :by_plan_ids, ->(plan_ids) { where(:id => {"$in" => plan_ids}) }

  scope :by_nationwide, ->(types) { where(:nationwide => {"$in" => types})}
  scope :by_dc_network, ->(types) { where(:dc_in_network => {"$in" => types})}
  scope :check_plan_offerings_for_single_carrier,  ->{ where(is_vertical: "true") }


  def carrier_profile=(new_carrier_profile)
    if new_carrier_profile.nil?
      self.carrier_profile_id = nil
    else
      raise ArgumentError, "expected CarrierProfile " unless new_carrier_profile.is_a? CarrierProfile
      self.carrier_profile_id = new_carrier_profile._id
      @carrier_profile = new_carrier_profile
    end
  end

  def carrier_profile
    return @carrier_profile if defined? @carrier_profile
    @carrier_profile = CarrierProfile.find(carrier_profile_id) unless carrier_profile_id.blank?
  end

  def plan_hsa
    name = self.name
    regex = name.match("HSA")
    regex.present? ? 'Yes' : 'No'
  end

  def deductible_integer
    (deductible && deductible.gsub(/\$/,'').gsub(/,/,'').to_i) || nil
  end

  def plan_deductible
    deductible_integer
  end

  def dental?
    coverage_kind && coverage_kind.downcase == "dental"
  end

  def health?
    coverage_kind && coverage_kind.downcase == "health"
  end

  def is_dental_only?
    dental?
  end

  def self.for_service_areas_and_carriers(service_area_carrier_pairs, active_year, metal_level = nil, coverage_kind = 'health')
    plan_criteria_set = service_area_carrier_pairs.map do |sap|
      criteria = {
        :carrier_profile_id => sap.first,
        :service_area_id => sap.last,
        :active_year => active_year,
        :coverage_kind => coverage_kind
      }
      criteria.merge(metal_level: metal_level) if metal_level.present?
      criteria
    end
    self.where("$or" => plan_criteria_set)
  end

  class << self

    def search_options(plans)
      options = {
        'plan_type': [],
        'plan_hsa': [],
        'metal_level': [],
        'plan_deductible': []
      }
      options.each do |option, _value|
        collected = plans.collect do |plan|
          if option == :metal_level
            MetalLevel.new(plan.send(option))
          else
            plan.send(option)
          end
        end.uniq.sort
        options[option] = collected unless collected.none?
      end
      options
    end
  end
end

class MetalLevel
  include Comparable
  attr_reader :name
  METAL_LEVEL_ORDER = %w[BRONZE SILVER GOLD PLATINUM].freeze
  def initialize(name)
    @name = name
  end

  def to_s
    @name
  end

  def <=>(metal_level)
    metal_level = safe_assign(metal_level)
    my_level = self.name.upcase
    compared_level = metal_level.name.upcase
    METAL_LEVEL_ORDER.index(my_level) <=> METAL_LEVEL_ORDER.index(compared_level)
  end

  def eql?(metal_level)
    metal_level = safe_assign(metal_level)
    METAL_LEVEL_ORDER.index(self.name) == METAL_LEVEL_ORDER.index(metal_level.name)
  end

  def hash
    @name.hash
  end

  private

  def safe_assign(metal_level)
    metal_level = MetalLevel.new(metal_level) if metal_level.is_a? String
    metal_level
  end
end

# rubocop:enable all

