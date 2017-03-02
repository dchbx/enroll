class BenefitCoveragePeriod
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_sponsorship

  field :title, type: String

  # Market where benefits are available
  field :service_market, type: String

  # Eligibility time period
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

  def second_lowest_cost_silver_plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a?(Plan)
    raise ArgumentError.new("slcsp metal level must be silver") unless new_plan.metal_level == "silver"
    self.slcsp_id = new_plan._id
    self.slcsp = new_plan._id
    @second_lowest_cost_silver_plan = new_plan
  end

  def second_lowest_cost_silver_plan
    return @second_lowest_cost_silver_plan if defined? @second_lowest_cost_silver_plan
    @second_lowest_cost_silver_plan = Plan.find(slcsp_id) unless slcsp_id.blank?
  end

  # The universe of products this sponsor may offer during this time period
  def benefit_products
  end

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  def contains?(date)
    (start_on <= date) && (date <= end_on)
  end

  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  def termination_effective_on_for(date)
    if open_enrollment_contains?(date)

      ##  Scendario: Open Enrollment is 11/1 - 1/31
        # 11/3  => 1/1
        # 11/22 => 1/1
        # 12/9  => 1/1
        # 12/23 => 1/31
        #   1/5 => 1/31
        #  1/17 => 2/28

      compare_date = date.end_of_month + 1.day

      return case
      when (compare_date < start_on)  # November
        start_on
      when compare_date == start_on   # December
        if date.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
          start_on
        else
          start_on.end_of_month
        end
      when compare_date > start_on    # January and forward
        if date.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
          date.end_of_month
        else
          date.next_month.end_of_month
        end
      end
    else
      dateOfTermMin   = TimeKeeper.date_of_record + HbxProfile::IndividualEnrollmentTerminationMinimum
      if (date < dateOfTermMin)
        # If selected date is less than 14 days from today, add 14 days to todays date and that is the termination date.
        TimeKeeper.date_of_record + HbxProfile::IndividualEnrollmentTerminationMinimum
      else
        # If selected date is greater than or equal to 14 days from today, the selected date itself is the termination date.
        date
      end

    end
  end

  def earliest_effective_date
    if TimeKeeper.date_of_record.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
      effective_date = TimeKeeper.date_of_record.end_of_month + 1.day
    else
      effective_date = TimeKeeper.date_of_record.next_month.end_of_month + 1.day
    end

    [effective_date, start_on].max
  end

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

    def find(id)
      organizations = Organization.where("hbx_profile.benefit_sponsorship.benefit_coverage_periods._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? all.select{ |bcp| bcp.id == id }.first : nil
    end

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
