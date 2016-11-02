class EligibilityDetermination
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers

  embedded_in :tax_household

  CSR_KINDS = %w(csr_100 csr_94 csr_87 csr_73)

  #   csr_0:   "02", # Native Americans
  #   limited: "03", # limited?
  CSR_KIND_TO_PLAN_VARIANT_MAP = {
      "csr_100" => "01",
      "csr_94"  => "06",
      "csr_87"  => "05",
      "csr_73"  => "04",
      "csr_0"   => "02",
      "limited" => "03"
    }
  CSR_KIND_TO_PLAN_VARIANT_MAP.default = "01"

  field :e_pdc_id, type: String
  field :benchmark_plan_id, type: BSON::ObjectId

  # Premium tax credit assistance eligibility.
  # Available to household with income between 100% and 400% of the Federal Poverty Level (FPL)
  field :max_aptc, type: Money, default: 0.00
  field :premium_credit_strategy_kind, type: String

  # Cost-sharing reduction assistance subsidies reduce out-of-pocket expenses by raising
  #   the plan actuarial value (the average out-of-pocket costs an insurer pays on a plan)
  # Available to households with income between 100-250% of FPL and enrolled in Silver plan.
  field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94
  field :csr_eligibility_kind, type: String, default: "csr_100"

  field :determined_at, type: DateTime

  # DEPRECATED - use determined_at
  field :determined_on, type: DateTime

  # Source will tell who determined / redetermined eligibility. Eg: Curam or Admin
  field :source, type: String

  before_validation :set_premium_credit_strategy, :set_determined_at

  validates_presence_of :determined_on, :max_aptc, :csr_percent_as_integer

  validates :premium_credit_strategy_kind,
    allow_blank: false,
    inclusion: {
      in: BenefitPackage::PREMIUM_CREDIT_STRATEGY_KINDS,
      message: "%{value} is not a valid premium credit strategy kind"
    }

  validates :csr_eligibility_kind,
    allow_blank: false,
    inclusion: {
      in: CSR_KINDS,
      message: "%{value} is not a valid cost sharing eligibility kind"
    }

  def csr_percent_as_integer=(new_csr_percent)
    super
    self.csr_eligibility_kind = case csr_percent_as_integer
    when 73
      "csr_73"
    when 87
      "csr_87"
    when 94
      "csr_94"
    else
      "csr_100"
    end
  end

  def family
    return nil unless tax_household
    tax_household.family
  end

  def benchmark_plan=(benchmark_plan_instance)
    return unless benchmark_plan_instance.is_a? Plan
    self.benchmark_plan_id = benchmark_plan_instance._id
    @benchmark_plan = benchmark_plan_instance
  end

  def benchmark_plan
    return @benchmark_plan if defined? @benchmark_plan
    @benchmark_plan = Plan.find(self.benchmark_plan_id) unless self.benchmark_plan_id.blank?
  end

  def csr_percent=(value)
    value ||= 0 #to handle value = nil
    raise "value out of range" if (value < 0 || value > 1)
    self.csr_percent_as_integer = Rational(value) * Rational(100)
  end

  def csr_percent
    (Rational(csr_percent_as_integer) / Rational(100)).to_f
  end

  def self.find(id)
    family = Family.where(:"households.tax_households.eligibility_determinations._id" => id).first

    if family.present?
      ed = family.households.flat_map() do |household|
        household.tax_households.flat_map() do |tax_household|
          tax_household.eligibility_determinations.detect { |ed| ed.id == id }
        end
      end
      ed.first unless ed.blank?
    end
  end

private
  def set_premium_credit_strategy
    self.premium_credit_strategy_kind ||= max_aptc > 0 ? self.premium_credit_strategy_kind = "allocated_lump_sum_credit" : self.premium_credit_strategy_kind = "unassisted"
  end

  def set_determined_at
    if tax_household && tax_household.submitted_at.present?
      self.determined_at ||= tax_household.submitted_at
    end
  end

end
