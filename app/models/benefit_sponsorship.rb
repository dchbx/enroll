class BenefitSponsorship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile
  # embedded_in :employer_profile

  # person/roles can determine which sponsor in a class has a relationship (offer products)
  # which benefit packages should be offered to person/roles

  SERVICE_MARKET_KINDS = %w(shop individual coverall)

  field :service_markets, type: Array, default: []
  validates_presence_of :service_markets

  # 2015, 2016, etc. (aka plan_year)
  embeds_many :benefit_coverage_periods
  embeds_many :geographic_rating_areas

  accepts_nested_attributes_for :benefit_coverage_periods, :geographic_rating_areas
  # Query Census member collection
  def census_employees
    @census_employees = CensusMembers::PlanDesignCensusEmployee.by_benefit_sponsorship(self)
  end

  def current_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  end

  def renewal_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record + 1.year) }
  end

  def earliest_effective_date
    current_benefit_period.earliest_effective_date if current_benefit_period
  end

  def benefit_coverage_period_by_effective_date(effective_date)
    benefit_coverage_periods.detect { |bcp| bcp.contains?(effective_date) }
  end


  # def is_under_special_enrollment_period?
  #   benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  # end

  def is_coverage_period_under_open_enrollment?
    benefit_coverage_periods.any? do |benefit_coverage_period|
      benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
    end
  end

  def self.find(id)
    orgs = Organization.where("hbx_profile.benefit_sponsorship._id" => BSON::ObjectId.from_string(id))
    orgs.size > 0 ? orgs.first.hbx_profile.benefit_sponsorship : nil
  end

  def current_benefit_period
    if renewal_benefit_coverage_period && renewal_benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
      renewal_benefit_coverage_period
    else
      current_benefit_coverage_period
    end
  end

# effective_coverage_period
# HBX: Jan-Dec
# Employers: year-over-year, e.g. Jun-May

# Shopping time range
# Benefit effective time range: can exceed one year
# Issuer begin date
# Issuer end date --

# Employer
# Effective start on date: Dec 1, 2015
# Effective end on date: Nov 30, 2016
# (policy) contract start on date
# (policy) contract end on date

# SHOP plan effective start on date Jan 1, 2015
# SHOP plan effective end on date: Dec 31, 2015

# product effective_start_on
# product effective_end_on

# 2015 SHOP plan that becomes effective Jan 1 2015
#   benefit_service_period between Jan 1 2015 and Nov 30, 2016

  class << self
    def advance_day(new_date)

      hbx_sponsors = Organization.exists("hbx_profile.benefit_sponsorship": true).reduce([]) { |memo, org| memo << org.hbx_profile }

      hbx_sponsors.each do |hbx_sponsor|
        hbx_sponsor.advance_day
        hbx_sponsor.advance_month   if new_date.day == 1
        hbx_sponsor.advance_quarter if new_date.day == 1 && [1, 4, 7, 10].include?(new_date.month)
        hbx_sponsor.advance_year    if new_date.day == 1 && new_date.month == 1
      end

      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period
      if renewal_benefit_coverage_period.present? && renewal_benefit_coverage_period.open_enrollment_start_on == new_date && !Rails.env.test?
        oe_begin = Enrollments::IndividualMarket::OpenEnrollmentBegin.new
        oe_begin.process_renewals
      end

      # # Find families with events today and trigger their respective workflow states
      # orgs = Organization.or(
      #   {:"employer_profile.plan_years.start_on" => new_date},
      #   {:"employer_profile.plan_years.end_on" => new_date - 1.day},
      #   {:"employer_profile.plan_years.open_enrollment_start_on" => new_date},
      #   {:"employer_profile.plan_years.open_enrollment_end_on" => new_date - 1.day},
      #   {:"employer_profile.workflow_state_transitions".elem_match => {
      #       "$and" => [
      #         {:transition_at.gte => (new_date.beginning_of_day - Settings.aca.shop_market.initial_application.ineligible_period_after_application_denial)},
      #         {:transition_at.lte => (new_date.end_of_day - Settings.aca.shop_market.initial_application.ineligible_period_after_application_denial)},
      #         {:to_state => "ineligible"}
      #       ]
      #     }
      #   }
      # )

      # orgs.each do |org|
      #   org.employer_profile.today = new_date
      #   org.employer_profile.advance_date! if org.employer_profile.may_advance_date?
      #   plan_year = org.employer_profile.published_plan_year
      #   plan_year.advance_date! if plan_year && plan_year.may_advance_date?
      #   plan_year
      # end
    end
  end

end
