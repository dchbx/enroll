module BenefitMarkets
  module Products
    class HealthProducts::HealthProduct < BenefitMarkets::Products::Product

      PRODUCT_PACKAGE_KINDS = [:single_issuer, :metal_level, :single_product]
      METAL_LEVEL_KINDS     = [:bronze, :silver, :gold, :platinum, :catastrophic]

      HEALTH_PLAN_MAP  = {
          hmo: "Health Maintenance Organization", # designated primary care physician (PCP) who's 
                                                  #   referral is required for specialists who are in-network
          ppo: "Preferred provider Organization", # health plan with a “preferred” network of providers 
                                                  #   in an area
          pos: "Point of Service",                # hmo/ppo hybrid. PCP referral for specialist required. 
                                                  #   In-network providers are lower cost, may access out-of-network 
                                                  #   providers at higher cost
          epo: "Exclusive Provider Network",      # hmo/ppo hybrid. PCP referral for specialist not required, but 
                                                  #   must pay out-of-pocket for doctors outside network
        }


      field :hios_id,                     type: String
      field :hios_base_id,                type: String
      field :csr_variant_id,              type: String

      field :health_plan_kind,            type: Symbol  # => :hmo, :ppo, :pos, :epo
      field :metal_level_kind,            type: Symbol  

      # Essential Health Benefit (EHB) percentage
      field :ehb,                         type: Float,    default: 0.0
      field :is_standard_plan,            type: Boolean,  default: false

      field :rx_formulary_url,            type: String
      field :hsa_eligibility,             type: Boolean,  default: false
      field :network_information,         type: String


      belongs_to  :renewal_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

      belongs_to  :catastrophic_age_off_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

      validates_presence_of :hios_id, :health_plan_kind, :ehb

      validates_numericality_of :ehb, greater_than: 0.0, less_than_or_equal_to: 1.0, allow_nil: false

      validate :product_package_kinds

      index({ hios_id: 1, "active_period.min": 1, "active_period.max": 1, name: 1 }, {name: "products_health_product_hios_active_period_name_index"})
      index({ "active_period.min": 1, "active_period.max": 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 }, {name: "health_products_a_period_market_c_kind_nationwide_name_index"})
      index({ csr_variant_id: 1}, {sparse: true, name: "product_health_products_csr_variant_index"})

      scope :standard_plans,      ->{ where(is_standard_plan: true) }

      scope :ppo_plans,           ->{ where(health_plan_kind: :ppo) }
      scope :pos_plans,           ->{ where(health_plan_kind: :pos) }
      scope :hmo_plans,           ->{ where(health_plan_kind: :hmo) }
      scope :epo_plans,           ->{ where(health_plan_kind: :epo) }

      scope :bronze_plans,        ->{ where(metal_level: :bronze) }
      scope :silver_plans,        ->{ where(metal_level: :silver) }
      scope :gold_plans,          ->{ where(metal_level: :gold) }
      scope :platinum_plans,      ->{ where(metal_level: :platinum) }
      scope :catastrophic_plans,  ->{ where(metal_level: :catastrophic) }


      validates :health_plan_kind,
                presence: true,
                inclusion: {in: HEALTH_PLAN_MAP.keys, message: "%{value} is not a valid health product kind"}

      validates :metal_level_kind,
                presence: true,
                inclusion: {in: METAL_LEVEL_KINDS, message: "%{value} is not a valid metal level kind"}


      alias_method :is_standard_plan?, :is_standard_plan
      alias_method :is_reference_plan_eligible?, :is_reference_plan_eligible

      def metal_level
        metal_level_kind.to_s
      end

      private

      def validate_product_package_kinds
        if !product_package_kinds.is_a?(Array) || product_package_kinds.detect { |pkg| !PRODUCT_PACKAGE_KINDS.include?(pkg) }
          errors.add(:product_package_kinds, :invalid)
        end
      end

    end
  end
end
