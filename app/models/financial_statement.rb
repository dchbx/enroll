# frozen_string_literal: true

require 'active_support/time'

class FinancialStatement
  include Mongoid::Document
  include Mongoid::Timestamps

  TAX_FILING_STATUS_TYPES = %w[tax_filer tax_dependent non_filer].freeze

  field :tax_filing_status, type: String
  field :is_tax_filing_together, type: Boolean

  field :eligibility_determination_id, type: BSON::ObjectId

  # Has access to employer-sponsored coverage that meets ACA minimum standard value and
  #   employee responsible premium amount is <= 9.5% of Household income
  field :is_enrolled_for_es_coverage, type: Boolean, default: false
  field :is_without_assistance, type: Boolean, default: true
  field :submitted_date, type: DateTime
  field :is_active, type: Boolean, default: true

  embedded_in :tax_household_member

  embeds_many :incomes
  accepts_nested_attributes_for :incomes

  embeds_many :deductions
  accepts_nested_attributes_for :deductions

  embeds_many :alternate_benefits
  accepts_nested_attributes_for :alternate_benefits

  validates :tax_filing_status,
            inclusion: { in: TAX_FILING_STATUS_TYPES, message: "%{value} is not a valid tax filing status" },
            allow_blank: true

  def family
    return nil unless tax_household_member
    tax_household_member.family
  end

  def applicant
    return nil unless tax_household_member
    tax_household_member.family_member
  end

  def eligibility_determination=(ed_instance)
    return unless ed_instance.is_a? EligibilityDetermination
    self.eligibility_determination_id = ed_instance._id
    @eligibility_determination = ed_instance
  end

  def eligibility_determination
    return nil unless tax_household_member
    return @eligibility_determination if defined? @eligibility_determination
    @eligibility_determination = tax_household_member.eligibility_determinations.detect { |elig_d| elig_d._id == self.eligibility_determination_id }
  end

  # Evaluate if receiving Alternative Benefits this year
  def is_receiving_benefit?
    return_value = false

    alternate_benefits.each do |alternate_benefit|
      return_value = is_receiving_benefits_this_year?(alternate_benefit)
      break if return_value
    end

    return_value
  end

  def compute_yearwise(incomes_or_deductions)
    income_deduction_per_year = Hash.new(0)

    incomes_or_deductions.each do |income_deduction|
      working_days_in_year = Float(52 * 5)
      daily_income = 0

      case income_deduction.frequency
      when "daily"
        daily_income = income_deduction.amount_in_cents
      when "weekly"
        daily_income = income_deduction.amount_in_cents / (working_days_in_year / 52)
      when "biweekly"
        daily_income = income_deduction.amount_in_cents / (working_days_in_year / 26)
      when "monthly"
        daily_income = income_deduction.amount_in_cents / (working_days_in_year / 12)
      when "quarterly"
        daily_income = income_deduction.amount_in_cents / (working_days_in_year / 4)
      when "half_yearly"
        daily_income = income_deduction.amount_in_cents / (working_days_in_year / 2)
      when "yearly"
        daily_income = income_deduction.amount_in_cents / working_days_in_year
      end

      income_deduction.start_date = TimeKeeper.date_of_record.beginning_of_year if income_deduction.start_date.to_s.eql? "01-01-0001" || income_deduction.start_date.blank?
      income_deduction.end_date   = TimeKeeper.date_of_record.end_of_year if income_deduction.end_date.to_s.eql? "01-01-0001" || income_deduction.end_date.blank?
      years = (income_deduction.start_date.year..income_deduction.end_date.year)

      years.to_a.each do |year|
        actual_days_worked = compute_actual_days_worked(year, income_deduction.start_date, income_deduction.end_date)
        income_deduction_per_year[year] += actual_days_worked * daily_income
      end
    end

    income_deduction_per_year.merge(income_deduction_per_year) do |_k, v|

      Integer(v)
    rescue StandardError
      v

    end
  end

  # Compute the actual days a person worked during one year
  def compute_actual_days_worked(year, start_date, end_date)
    working_days_in_year = Float(52 * 5)

    start_date_to_consider = if Date.new(year, 1, 1) < start_date
                               start_date
                             else
                               Date.new(year, 1, 1)
                             end

    end_date_to_consider = if Date.new(year, 1, 1).end_of_year < end_date
                             Date.new(year, 1, 1).end_of_year
                           else
                             end_date
                           end

    # we have to add one to include last day of work. We multiply by working_days_in_year/365 to remove weekends.
    ((end_date_to_consider - start_date_to_consider + 1).to_i * (working_days_in_year / 365)).to_i #actual days worked in 'year'
  end

  def is_receiving_benefits_this_year?(alternate_benefit)
    alternate_benefit.start_date = TimeKeeper.date_of_record.beginning_of_year if alternate_benefit.start_date.blank?
    alternate_benefit.end_date =   TimeKeeper.date_of_record.end_of_year if alternate_benefit.end_date.blank?
    (alternate_benefit.start_date.year..alternate_benefit.end_date.year).include? TimeKeeper.date_of_record.year
  end

  def total_incomes_by_year
    incomes_by_year = compute_yearwise(incomes)
    deductions_by_year = compute_yearwise(deductions)

    years = incomes_by_year.keys | deductions_by_year.keys

    total_incomes = {}

    years.each do |y|
      income_this_year = incomes_by_year[y] || 0
      deductions_this_year = deductions_by_year[y] || 0
      total_incomes[y] = (income_this_year - deductions_this_year) * 0.01
    end
    total_incomes
  end

  def is_tax_filing_together?
    self.is_tax_filing_together
  end

  def is_enrolled_for_es_coverage?
    self.is_enrolled_for_es_coverage
  end

  def is_without_assistance?
    self.is_without_assistance
  end

  def is_active?
    self.is_active
  end

end
