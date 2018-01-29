# A time period during which Organizations, including {HbxProfile}, who are eligible for a {BenefitSponsorship}, may offer
# {BenefitPackage}(s) to participants within a market place. Each {BenefitCoveragePeriod} includes an open enrollment
# period, during which eligible partipants may enroll.

class BenefitCoveragePeriod
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_sponsorship

  # This Benefit Coverage Period's name
  field :title, type: String

  # Market where benefits are available
  field :service_market, type: String

  field :start_on, type: Date
  field :end_on, type: Date
  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  # Second Lowest Cost Silver Plan, by rating area (only one rating area in DC)
  field :slcsp, type: BSON::ObjectId
  field :slcsp_id, type: BSON::ObjectId

  # embeds_many :open_enrollment_periods, class_name: "EnrollmentPeriod"
  embeds_many :benefit_packages

  accepts_nested_attributes_for :benefit_packages

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, message: "is invalid"

  validates :service_market,
    inclusion: { in: BenefitSponsorship::SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

  validate :end_date_follows_start_date

  before_save :set_title

  scope :by_date, ->(date) { where({:"start_on".lte => date, :"end_on".gte => date}) }

  # Sets the ACA Second Lowest Cost Silver Plan (SLCSP) reference plan
  #
  # @raise [ArgumentError] if the referenced plan is not silver metal level
  #
  # @param new_plan [ Plan ] The reference plan.
  def second_lowest_cost_silver_plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a?(Plan)
    raise ArgumentError.new("slcsp metal level must be silver") unless new_plan.metal_level == "silver"
    self.slcsp_id = new_plan._id
    self.slcsp = new_plan._id
    @second_lowest_cost_silver_plan = new_plan
  end

  # Gets the ACA Second Lowest Cost Silver Plan (SLCSP) reference plan
  #
  # @return [ Plan ] reference plan
  def second_lowest_cost_silver_plan
    return @second_lowest_cost_silver_plan if defined? @second_lowest_cost_silver_plan
    @second_lowest_cost_silver_plan = Plan.find(slcsp_id) unless slcsp_id.blank?
  end

  # @todo Available products from which this sponsor may offer benefits during this benefit coverage period
  def benefit_products
  end

  # Sets the earliest coverage effective date
  #
  # @overload start_on=(new_date)
  #
  # @param new_date [ Date ] The earliest coverage effective date
  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  # Sets the latest date a participant may enroll for coverage
  #
  # @overload end_on=(new_date)
  #
  # @param new_date [ Date ] The latest date a participant may enroll for coverage
  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  # Determine if this date is within the benefit coverage period start/end dates
  #
  # @example Is the date within the benefit coverage period?
  #   model.contains?(date)
  #
  # @return [ true, false ] true if the date falls within the period, false if the date is outside the period
  def contains?(date)
    (start_on <= date) && (date <= end_on)
  end

  # Determine if this date is within the open enrollment period start/end dates
  #
  # @param date [ Date ] The comparision date
  #
  # @example Is the date within the open enrollment period?
  #   model.open_enrollment_contains?(date)
  #
  # @return [ true, false ] true if the date falls within the period, false if the date is outside the period
  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  # The earliest enrollment termination effective date, based on this date and site settings
  #
  # @param date [ Date ] The comparision date.
  #
  # @example When is the earliest termination effective date?
  #   model.termination_effective_on_for(date)
  #
  # @return [ Date ] the earliest termination effective date.
  def termination_effective_on_for(date)
    # Add guard to prevent the temination date exceeding end date in the Individual Market
    [date, end_on].min # see 20996
  end

  # The earliest coverage start effective date, based on today's date and site settings
  #
  # @example When is the earliest coverage start effective date?
  #   model.earliest_effective_date
  #
  # @return [ Date ] the earliest coverage start effective date
  def earliest_effective_date
    if TimeKeeper.date_of_record.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
      effective_date = TimeKeeper.date_of_record.end_of_month + 1.day
    else
      effective_date = TimeKeeper.date_of_record.next_month.end_of_month + 1.day
    end

    [[effective_date, start_on].max, end_on].min
  end

  # Determine list of available products (plans), based on member enrollment eligibility for each {BenefitPackage} under this
  # {BenefitCoveragePeriod}. In the Individual market, BenefitPackage types may include Catastrophic, Cost Sharing
  # Reduction (CSR), etc., and eligibility criteria such as member age, ethnicity, residency and lawful presence.
  #
  # @param hbx_enrollment_members [ Array ] the list of enrolling members
  # @param coverage_kind [ String ] the benefit type.  Only 'health' is currently supported
  # @param tax_household [ TaxHousehold ] the tax household members belong to if eligible for financial assistance
  #
  # @return [ Array<Plan> ] the list of eligible products
  def elected_plans_by_enrollment_members(hbx_enrollment_members, coverage_kind, tax_household=nil)
    ivl_bgs = []
    benefit_packages.each do |bg|
      satisfied = true
      family = hbx_enrollment_members.first.hbx_enrollment.family
      hbx_enrollment_members.map(&:family_member).each do |family_member|
        consumer_role = family_member.person.consumer_role
        resident_role = family_member.person.resident_role
        unless resident_role.nil?
          rule = InsuredEligibleForBenefitRule.new(resident_role, bg, coverage_kind: coverage_kind, family: family)
        else
          rule = InsuredEligibleForBenefitRule.new(consumer_role, bg, { coverage_kind: coverage_kind, family: family, new_effective_on: hbx_enrollment_members.first.hbx_enrollment.effective_on })
        end
        satisfied = false and break unless rule.satisfied?[0]
      end
      ivl_bgs << bg if satisfied
    end

    ivl_bgs = ivl_bgs.uniq
    elected_plan_ids = ivl_bgs.map(&:benefit_ids).flatten.uniq
    Plan.individual_plans(coverage_kind: coverage_kind, active_year: start_on.year, tax_household: tax_household).by_plan_ids(elected_plan_ids).entries
  end

  ## Class methods
  class << self

    # The HBX benefit coverage period instance for this identifier
    #
    # @param id [ String ] the BSON object identifier
    #
    # @example Which HBX benefit coverage period matches this id?
    #   BenefitCoveragePeriod.find(id)
    #
    # @return [ BenefitCoveragePeriod ] the matching HBX benefit coverage period instance
    def find(id)
      organizations = Organization.where("hbx_profile.benefit_sponsorship.benefit_coverage_periods._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? all.select{ |bcp| bcp.id == id }.first : nil
    end

    # The HBX benefit coverage period instance that includes this date within its start and end dates
    #
    # @param date [ Date ] the comparison date
    #
    # @example Which HBX benefit coverage period covers this date?
    #   BenefitCoveragePeriod.find_by_date(date)
    #
    # @return [ BenefitCoveragePeriod ] the matching HBX benefit coverage period instance
    def find_by_date(date)
      organizations = Organization.where(
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.start_on".lte => date,
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.end_on".gte => date)
      if organizations.size > 0
        bcps = organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods
        bcps.select{ |bcp| bcp.start_on <= date && bcp.end_on >= date }.first
      else
        nil
      end
    end

    # All HBX benefit coverage periods
    #
    # @example Which HBX benefit coverage periods are defined?
    #   BenefitCoveragePeriod.all
    #
    # @return [ Array ] the list of HBX benefit coverage periods
    def all
      organizations = Organization.exists(:"hbx_profile.benefit_sponsorship.benefit_coverage_periods" => true)
      organizations.size > 0 ? organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods : nil
    end

  end

private
  def end_date_follows_start_date
    return unless self.end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end

  def set_title
    return if title.present?
    service_market == "shop" ? market_name = "SHOP" : market_name = "Individual"
    self.title = "#{market_name} Market Benefits #{start_on.year}"
  end

end
