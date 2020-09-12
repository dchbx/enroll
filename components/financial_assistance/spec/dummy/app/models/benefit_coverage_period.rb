# frozen_string_literal: true

# rubocop:disable all

class BenefitCoveragePeriod
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_sponsorship

  field :title, type: String

  field :service_market, type: String

  field :start_on, type: Date
  field :end_on, type: Date
  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  field :slcsp, type: BSON::ObjectId
  field :slcsp_id, type: BSON::ObjectId

  embeds_many :benefit_packages

  accepts_nested_attributes_for :benefit_packages

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, message: "is invalid"

  validates :service_market,
            inclusion: { in: BenefitSponsorship::SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

  validate :end_date_follows_start_date

  before_save :set_title

  scope :by_date, ->(date) { where({:start_on.lte => date, :end_on.gte => date}) }

  def second_lowest_cost_silver_plan=(new_plan)
    raise ArgumentError, "expected Plan" unless new_plan.is_a?(Plan)
    raise ArgumentError, "slcsp metal level must be silver" unless new_plan.metal_level == "silver"
    self.slcsp_id = new_plan._id
    self.slcsp = new_plan._id
    @second_lowest_cost_silver_plan = new_plan
  end

  def second_lowest_cost_silver_plan
    return @second_lowest_cost_silver_plan if defined? @second_lowest_cost_silver_plan
    @second_lowest_cost_silver_plan = Plan.find(slcsp_id) unless slcsp_id.blank?
  end

  def benefit_products; end

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
    [date, end_on].min # see 20996
  end

  def earliest_effective_date
    effective_date = if TimeKeeper.date_of_record.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
                       TimeKeeper.date_of_record.end_of_month + 1.day
                     else
                       TimeKeeper.date_of_record.next_month.end_of_month + 1.day
                     end

    [[effective_date, start_on].max, end_on].min
  end

  def elected_plans_by_enrollment_members(hbx_enrollment_members, coverage_kind, tax_household = nil, market = nil)
    ivl_bgs = []
    hbx_enrollment = hbx_enrollment_members.first.hbx_enrollment
    benefit_packages.each do |bg|
      satisfied = true
      family = hbx_enrollment.family
      hbx_enrollment_members.map(&:family_member).each do |family_member|
        consumer_role = family_member.person.consumer_role if family_member.person.is_consumer_role_active?
        resident_role = family_member.person.resident_role if family_member.person.is_resident_role_active?
        rule = if resident_role.nil?
                 InsuredEligibleForBenefitRule.new(consumer_role, bg, { coverage_kind: coverage_kind, family: family, new_effective_on: hbx_enrollment.effective_on,  market_kind: market})
               else
                 InsuredEligibleForBenefitRule.new(resident_role, bg, coverage_kind: coverage_kind, family: family, market_kind: market)
               end
        (satisfied = false) && break unless rule.satisfied?[0]
      end
      ivl_bgs << bg if satisfied
    end

    ivl_bgs = ivl_bgs.uniq
    elected_plan_ids = ivl_bgs.map(&:benefit_ids).flatten.uniq
    Plan.individual_plans(coverage_kind: coverage_kind, active_year: start_on.year, tax_household: tax_household, hbx_enrollment: hbx_enrollment).by_plan_ids(elected_plan_ids).entries
  end

  ## Class methods
  class << self
    def find(id)
      organizations = Organization.where("hbx_profile.benefit_sponsorship.benefit_coverage_periods._id" => BSON::ObjectId.from_string(id))
      !organizations.empty? ? all.select{ |bcp| bcp.id == id }.first : nil
    end

    def find_by_date(date)
      organizations = Organization.where(
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.start_on".lte => date,
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.end_on".gte => date
      )
      unless organizations.empty?
        bcps = organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods
        bcps.select{ |bcp| bcp.start_on <= date && bcp.end_on >= date }.first
      end
    end

    def all
      organizations = Organization.exists(:"hbx_profile.benefit_sponsorship.benefit_coverage_periods" => true)
      !organizations.empty? ? organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods : nil
    end

  end

  private

  def end_date_follows_start_date
    return unless self.end_on.present?
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end

  def set_title
    return if title.present?
    market_name = service_market == "shop" ? "SHOP" : "Individual"
    self.title = "#{market_name} Market Benefits #{start_on.year}"
  end

end

# rubocop:enable all
