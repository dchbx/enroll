class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
#  include Mongoid::Versioning

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum dental]
  MARKET_KINDS = %w(shop individual)
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo]
  DENTAL_METAL_LEVEL_KINDS = %w[high low]


  field :hbx_id, type: Integer
  field :active_year, type: Integer
  field :market, type: String
  field :coverage_kind, type: String
  field :carrier_profile_id, type: BSON::ObjectId
  field :metal_level, type: String

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

  # TODO deprecate after migrating SBCs for years prior to 2016
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

  # In MongoDB, the order of fields in an index should be:
  #   First: fields queried for exact values, in an order that most quickly reduces set
  #   Second: fields used to sort
  #   Third: fields queried for a range of values

  index({ hbx_id: 1, name: 1 })
  index({ hios_id: 1, active_year: 1, name: 1 })
  index({ active_year: 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 })
  index({ renewal_plan_id: 1, name: 1 })
  index({ name: 1 })
  index({ csr_variant_id: 1}, {sparse: true})

  # 2015, "94506DC0390006-01"
  index(
      {
        active_year: 1,
        hios_id: 1,
        "premium_tables.age": 1,
        "premium_tables.start_on": 1,
        "premium_tables.end_on": 1
      },
      { name: "plan_premium_age" }
    )

  # 92479DC0020002, 2015, 32, 2015-04-01, 2015-06-30
  index({ hios_id: 1, active_year: 1, "premium_tables.age": 1, "premium_tables.start_on": 1, "premium_tables.end_on": 1 }, {name: "plan_premium_age_deprecated"})

  # 2015, individual, health, silver, 04
  index({ active_year: 1, market: 1, coverage_kind: 1, metal_level: 1, csr_variant_id: 1 })

  # 2015, individual, health, gold
  index({ active_year: 1, market: 1, coverage_kind: 1, metal_level: 1, name: 1 })

  # 2015, individual, health, uhc
  index({ active_year: 1, market: 1, coverage_kind: 1, carrier_profile_id: 1, name: 1 })

  # 2015, individual, health, uhc, gold
  index({ active_year: 1, market: 1, coverage_kind: 1, carrier_profile_id: 1, metal_level: 1, name: 1 })

  index({ "premium_tables.age" => 1 })
  index({ "premium_tables.age" => 1, "premium_tables.start_on" => 1, "premium_tables.end_on" => 1 })

  validates_presence_of :name, :hios_id, :active_year, :metal_level, :market, :carrier_profile_id

  validates :coverage_kind,
   allow_blank: false,
   inclusion: {
     in: COVERAGE_KINDS,
     message: "%{value} is not a valid coverage kind"
  }

  validates :metal_level,
   allow_blank: false,
   inclusion: {
     in: METAL_LEVEL_KINDS,
     message: "%{value} is not a valid metal level kind"
  }

  validates :dental_level,
   inclusion: {
     in: DENTAL_METAL_LEVEL_KINDS,
     message: "%{value} is not a valid dental metal level kind"
  }, if: Proc.new{|a| a.active_year.present? && a.active_year > 2015 && a.coverage_kind == "dental" } # we do not check for 2015 plans because, they are already imported with metal_level="dental"

  validates :market,
   allow_blank: false,
   inclusion: {
     in: MARKET_KINDS,
     message: "%{value} is not a valid market"
   }

  validates_inclusion_of :active_year,
    in: 2014..(TimeKeeper.date_of_record.year + 3),
    message: "%{value} is an invalid active year"

  ## Scopes
  default_scope -> {order("name ASC")}

  # Metal level
  scope :platinum_level,      ->{ where(metal_level: "platinum") }
  scope :gold_level,          ->{ where(metal_level: "gold") }
  scope :silver_level,        ->{ where(metal_level: "silver") }
  scope :bronze_level,        ->{ where(metal_level: "bronze") }
  scope :catastrophic_level,  ->{ where(metal_level: "catastrophic") }


  scope :metal_level_sans_silver,  ->{ where(:metal_leval.in => %w(platinum gold bronze catastrophic))}

  # Plan.metal_level_sans_silver.silver_level_by_csr_kind("csr_87")
  scope :silver_level_by_csr_kind, ->(csr_kind = "csr_100"){ where(
                                          metal_level: "silver").and(
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

  scope :by_active_year,        ->(active_year = TimeKeeper.date_of_record.year) { where(active_year: active_year) }
  scope :by_metal_level,        ->(metal_level) { where(metal_level: metal_level) }

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
    scope :individual_health_by_active_year, ->(active_year) {where(active_year: active_year, market: "individual", coverage_kind: "health", hios_id: /-01$/ ) }
  # END DEPRECATED

  scope :valid_shop_by_carrier_and_year, ->(carrier_profile_id, year) {
    where(
        carrier_profile_id: carrier_profile_id,
        active_year: year,
        market: "shop",
        hios_id: { "$not" => /-00$/ },
        metal_level: { "$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS }
      )
  }
  scope :valid_shop_by_metal_level_and_year, ->(metal_level, year) {
    where(
        active_year: year,
        market: "shop",
        hios_id: /-01$/,
        metal_level: metal_level
      )
  }

  scope :with_premium_tables, ->{ where(:premium_tables.exists => true) }


  scope :shop_health_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "shop",
          coverage_kind: "health"
        )
    }

  scope :shop_dental_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "shop",
          coverage_kind: "dental"
        )
    }

  scope :individual_health_by_active_year_and_csr_kind, ->(active_year, csr_kind = "csr_100") {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
      )
    }

  scope :individual_health_by_active_year_and_csr_kind_with_catastrophic, ->(active_year, csr_kind = "csr_100") {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze catastrophic), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
      )
    }

  scope :individual_dental_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "individual",
          coverage_kind: "dental"
        )
    }

  scope :individual_health_by_active_year_carrier_profile_csr_kind, ->(active_year, carrier_profile_id, csr_kind) {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health", :carrier_profile_id => carrier_profile_id },
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
    )
  }

  scope :by_health_metal_levels,                ->(metal_levels)    { any_in(metal_level: metal_levels) }
  scope :by_carrier_profile,                    ->(carrier_profile_id) { where(carrier_profile_id: carrier_profile_id) }

  scope :health_metal_levels_all,               ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS << "catastrophic") }
  scope :health_metal_levels_sans_catastrophic, ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS) }
  scope :health_metal_nin_catastropic,          ->{ not_in(metal_level: "catastrophic") }


  scope :by_plan_ids, ->(plan_ids) { where(:id => {"$in" => plan_ids}) }

  # Carriers: use class method (which may be chained)
  def self.find_by_carrier_profile(carrier_profile)
    where(carrier_profile_id: carrier_profile._id)
  end

  def metal_level=(new_metal_level)
    write_attribute(:metal_level, new_metal_level.to_s.downcase)
  end

  def coverage_kind=(new_coverage_kind)
    write_attribute(:coverage_kind, new_coverage_kind.to_s.downcase)
  end

  # belongs_to CarrierProfile
  def carrier_profile=(new_carrier_profile)
    if new_carrier_profile.nil?
      self.carrier_profile_id = nil
    else
      raise ArgumentError.new("expected CarrierProfile ") unless new_carrier_profile.is_a? CarrierProfile
      self.carrier_profile_id = new_carrier_profile._id
      @carrier_profile = new_carrier_profile
    end
  end

  def carrier_profile
    return @carrier_profile if defined? @carrier_profile
    @carrier_profile = CarrierProfile.find(carrier_profile_id) unless carrier_profile_id.blank?
  end

  def cat_age_off_renewal_plan
    return @cat_age_off_renewal_plan if defined? @cat_age_off_renewal_plan
    @cat_age_off_renewal_plan = Plan.find(cat_age_off_renewal_plan_id) unless cat_age_off_renewal_plan_id.blank?
  end

  # has_one renewal_plan
  def renewal_plan=(new_renewal_plan)
    if new_renewal_plan.nil?
      self.renewal_plan_id = nil
    else
      raise ArgumentError.new("expected Plan ") unless new_renewal_plan.is_a? Plan
      self.renewal_plan_id = new_renewal_plan._id
      @renewal_plan = new_renewal_plan
    end
  end

  def renewal_plan
    return @renewal_plan if defined? @renewal_plan
    @renewal_plan = Plan.find(renewal_plan_id) unless renewal_plan_id.blank?
  end

  def minimum_age
    if premium_tables.count > 0
      premium_tables.min(:age)
    else
      read_attribute(:minimum_age)
    end
  end

  def bound_age(given_age)
    return minimum_age if given_age < minimum_age
    return maximum_age if given_age > maximum_age
    given_age
  end

  def premium_table_for(schedule_date)
    self.premium_tables.select do |pt|
      (pt.start_on <= schedule_date) && (pt.end_on >= schedule_date)
    end
  end

  def premium_for(schedule_date, age)
    bound_age_val = bound_age(age)
    begin
      value = premium_table_for(schedule_date).detect {|pt| pt.age == bound_age_val }.cost
      BigDecimal.new("#{value}").round(2).to_f
    rescue
      raise [self.id, bound_age_val, schedule_date, age].inspect
    end
  end

  def is_dental_only?
    return false if self.coverage_kind.blank?
    self.coverage_kind.downcase == "dental"
  end

  def can_use_aptc?
    metal_level != 'catastrophic'
  end

  def ehb
    percent = read_attribute(:ehb)
    (percent && percent > 0) ? percent : 1
  end

  def is_csr?
    (EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.values - [EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.default]).include? csr_variant_id
  end

  def hsa_plan?
    name = self.name
    regex = name.match("HSA")
    if regex.present?
      return true
    else
      return false
    end
  end

  def renewal_plan_type
    hios = self.hios_base_id
    kp = ["94506DC0390001","94506DC0390002","94506DC0390003","94506DC0390004","94506DC0390005","94506DC0390006","94506DC0390007","94506DC0390008","94506DC0390009","94506DC0390010","94506DC0390011"]
    cf_nonhsa = ["78079DC0160001","78079DC0160002","86052DC0400003"]
    cf_reg = ["86052DC0400001","86052DC0400002","86052DC0400004","86052DC0400007","86052DC0400008","78079DC0210001","78079DC0210002","78079DC0210003","78079DC0210004"]
    cf_hsa = ["86052DC0400005","86052DC0400006","86052DC0400009"]
    return "2017 Plan" if self.active_year != 2016    
    if kp.include?(hios)
      return "KP"
    elsif cf_nonhsa.include?(hios)
      return "CFNONHSA"
    elsif cf_reg.include?(hios)
      return "CFREG"
    elsif cf_hsa.include?(hios)
      return "CFHSA"
    end
  end

  class << self

    def monthly_premium(plan_year, hios_id, insured_age, coverage_begin_date)
      result = []
      if plan_year.to_s == coverage_begin_date.to_date.year.to_s
        [insured_age].flatten.each do |age|
          cost = Plan.find_by(active_year: plan_year, hios_id: hios_id)
          .premium_tables.where(:age => age, :start_on.lte => coverage_begin_date, :end_on.gte => coverage_begin_date)
          .entries.first.cost
          result << { age: age, cost: cost }
        end
      end
      result
    end

    def valid_shop_health_plans(type="carrier", key=nil, year_of_plans=TimeKeeper.date_of_record.year)
      Rails.cache.fetch("plans-#{Plan.count}-for-#{key.to_s}-at-#{year_of_plans}-ofkind-health", expires_in: 5.hour) do
        Plan.public_send("valid_shop_by_#{type}_and_year", key.to_s, year_of_plans).where({coverage_kind: "health"}).to_a
      end
    end

    def valid_for_carrier(active_year)
      # carrier_ids = Plan.shop_dental_by_active_year(active_year).map(&:carrier_profile_id).uniq
      # carrier_ids.map{|c| org= Organization.where(:'carrier_profile._id' => c).first;org}
      Plan.shop_dental_by_active_year(active_year).map(&:carrier_profile).uniq
    end

    def valid_shop_dental_plans(type="carrier", key=nil, year_of_plans=TimeKeeper.date_of_record.year)
      Rails.cache.fetch("dental-plans-#{Plan.count}-for-#{key.to_s}-at-#{year_of_plans}", expires_in: 5.hour) do
        Plan.public_send("shop_dental_by_active_year", year_of_plans).to_a
      end
    end

    def reference_plan_metal_level_for_options
      REFERENCE_PLAN_METAL_LEVELS.map{|k| [k.humanize, k]}
    end

    def individual_plans(coverage_kind:, active_year:, tax_household:)
      case coverage_kind
      when 'dental'
        Plan.individual_dental_by_active_year(active_year).with_premium_tables
      when 'health'
        csr_kind = tax_household.try(:latest_eligibility_determination).try(:csr_eligibility_kind)
        if csr_kind.present?
          Plan.individual_health_by_active_year_and_csr_kind_with_catastrophic(active_year, csr_kind).with_premium_tables
        else
          Plan.individual_health_by_active_year_and_csr_kind_with_catastrophic(active_year).with_premium_tables
        end
      end
    end
  end
end
