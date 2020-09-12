# frozen_string_literal: true

# rubocop:disable all

class BenefitSponsorship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile
  # embedded_in :employer_profile

  # person/roles can determine which sponsor in a class has a relationship (offer products)
  # which benefit packages should be offered to person/roles

  SERVICE_MARKET_KINDS = %w[shop individual coverall].freeze

  field :service_markets, type: Array, default: []

  # 2015, 2016, etc. (aka plan_year)
  embeds_many :benefit_coverage_periods
  embeds_many :geographic_rating_areas

  accepts_nested_attributes_for :benefit_coverage_periods, :geographic_rating_areas

  validates_presence_of :service_markets

  def current_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  end

  def renewal_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record + 1.year) }
  end

  def earliest_effective_date
    current_benefit_period&.earliest_effective_date
  end

  def benefit_coverage_period_by_effective_date(effective_date)
    benefit_coverage_periods.detect { |bcp| bcp.contains?(effective_date) }
  end

  # def is_under_special_enrollment_period?
  #   benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  # end

  def is_under_open_enrollment?
    benefit_coverage_periods.any? do |benefit_coverage_period|
      benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
    end
  end

  def self.find(id)
    orgs = Organization.where("hbx_profile.benefit_sponsorship._id" => BSON::ObjectId.from_string(id))
    !orgs.empty? ? orgs.first.hbx_profile.benefit_sponsorship : nil
  end

  def current_benefit_period
    if renewal_benefit_coverage_period&.open_enrollment_contains?(TimeKeeper.date_of_record)
      renewal_benefit_coverage_period
    else
      current_benefit_coverage_period
    end
  end

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
    end
  end
end

# rubocop:enable all
