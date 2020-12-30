class Products::QhpCostShareVariance
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  # Component plus variant
  field :hios_plan_and_variant_id, type: String
  field :plan_marketing_name, type: String
  field :metal_level, type: String
  field :csr_variation_type, type: String
  field :product_id, type: String

  field :issuer_actuarial_value, type: String
  field :av_calculator_output_number, type: String

  field :medical_and_drug_deductibles_integrated, type: String
  field :medical_and_drug_max_out_of_pocket_integrated, type: String
  field :multiple_provider_tiers, type: String
  field :first_tier_utilization, type: String
  field :second_tier_utilization, type: String

  field :default_copay_in_network, type: String
  field :default_copay_out_of_network, type: String
  field :default_co_insurance_in_network, type: String
  field :default_co_insurance_out_of_network, type: String

  ## SBC Scenario
  field :having_baby_deductible, type: String
  field :having_baby_co_payment, type: String
  field :having_baby_co_insurance, type: String
  field :having_baby_limit, type: String
  field :having_diabetes_deductible, type: String
  field :having_diabetes_copay, type: String
  field :having_diabetes_co_insurance, type: String
  field :having_diabetes_limit, type: String

  embeds_one :qhp_deductable,
    class_name: "Products::QhpDeductable",
    cascade_callbacks: true,
    validate: true

  embeds_many :qhp_maximum_out_of_pockets,
    class_name: "Products::QhpMaximumOutOfPocket",
    cascade_callbacks: true,
    validate: true

  embeds_many :qhp_service_visits,
    class_name: "Products::QhpServiceVisit",
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :qhp_maximum_out_of_pockets, :qhp_service_visits


  def self.find_qhp(ids, year)
    Products::Qhp.by_hios_ids_and_active_year(ids.map { |str| str[0..13] }, year)
  end

  def self.find_qhp_cost_share_variances(ids, year, coverage_kind)
    csvs = find_qhp(ids, year).map(&:qhp_cost_share_variances).flatten
    ids = ids.map{|a| a+"-01"} if coverage_kind == "dental"
    csvs.select{ |a| ids.include?(a.hios_plan_and_variant_id) }
  end

  def plan
    # return @qhp_plan if defined? @qhp_plan
    Rails.cache.fetch("qcsv-plan-#{qhp.active_year}-hios-id-#{hios_plan_and_variant_id}", expires_in: 5.hour) do
      plan = Plan.where(active_year: qhp.active_year, hios_id: hios_plan_and_variant_id).first
      if plan.blank?
        plan = Plan.where(active_year: qhp.active_year, hios_id: hios_plan_and_variant_id.split('-')[0]).first if dental?
      end
      plan
    end
  end

  def product
    if product_id.present?
      ::BenefitMarkets::Products::Product.find(product_id)
    else
      Rails.cache.fetch("qcsv-product-#{qhp.active_year}-hios-id-#{hios_plan_and_variant_id}", expires_in: 5.hours) do
        product = BenefitMarkets::Products::Product.where(hios_id: /#{hios_plan_and_variant_id}/).select{|a| a.active_year == qhp.active_year}.first
        if product.blank?
          product = BenefitMarkets::Products::Product.where(hios_id: /#{hios_plan_and_variant_id.split('-')[0]}/).select{|a| a.active_year == qhp.active_year}.first if dental?
        end
        product
      end
    end
  end

  def product_for(market_kind = 'aca_shop')
    qhp_product = product

    return qhp_product if qhp_product.benefit_market_kind == market_kind.to_sym || dental?

    Rails.cache.fetch("qcsv--#{market_kind}-product-#{qhp.active_year}-hios-id-#{hios_plan_and_variant_id}", expires_in: 5.hours) do
      BenefitMarkets::Products::Product.where(
        :hios_base_id => /#{qhp_product.hios_base_id}/,
        :"application_period.min".gte => Date.new(qhp.active_year, 1, 1), :"application_period.max".lte => Date.new(qhp.active_year, 1, 1).end_of_year,
        :kind => qhp_product.kind,
        :benefit_market_kind => market_kind.to_sym
      ).first
    end
  end

  private

  def dental?
    qhp.metal_level == "dental"
  end
end
