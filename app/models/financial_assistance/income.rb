class FinancialAssistance::Income
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application, class_name: "::FinancialAssistance::Application"

  TITLE_SIZE_RANGE = 3..30
  KINDS = %W(
    alimony_and_maintenance
    american_indian_and_alaskan_native
    capital_gains
    dividend
    employer_funded_disability
    estate_trust
    farming_and_fishing
    foreign
    interest
    lump_sum_amount
    military
    net_self_employment
    other
    pension_retirement_benefits
    permanent_workers_compensation
    prizes_and_awards
    rental_and_royalty
    scholorship_payments
    social_security_benefit
    supplemental_security_income
    tax_exempt_interest
    unemployment_insurance
    wages_and_salaries
    income_from_irs
  )

  FREQUENCY_KINDS = %W(biweekly daily half_yearly monthly quarterly weekly yearly)

  TAX_FORM_KINDS = %W(1040 1040A 1040EZ 1040NR 1040NR-EZ )

  field :title, type: String
  field :kind, as: :income_type, type: String
  field :hours_per_week, type: Integer, default: 0
  field :amount, type: Integer, default: 0
  field :amount_tax_exempt, type: Integer, default: 0
  field :frequency_kind, type: String
  field :start_on, type: Date
  field :end_on, type: Date
  field :is_projected, type: Boolean, default: false
  field :tax_form, type: String
  field :employer_name, type: String
  field :employer_id, type: Integer
  field :income_from_native_american, type: Boolean
  field :has_education_scholarship_income, type: Boolean
  field :submitted_at, type: DateTime

  validates_length_of :title, 
                      in: TITLE_SIZE_RANGE, 
                      allow_nil: true,
                      message: "pick a name length between #{TITLE_SIZE_RANGE}"

  validates :amount,          presence: true,
                              numericality: { greater_than: 0, message: "%{value} must be greater than $0" }
  validates :kind,            presence: true,
                              inclusion: { in: KINDS, message: "%{value} is not a valid income type" }
  validates :frequency_kind,  presence: true,
                              inclusion: { in: FREQUENCY_KINDS, message: "%{value} is not a valid frequency" }
  validates :start_on,        presence: true

  validates :tax_form,        presence: true,
                              inclusion: { in: TAX_FORM_KINDS, message: "%{value} is not a valid tax form type" }
  validate :start_on_must_precede_end_on

  before_create :set_submission_timestamp


  def hours_worked_per_week
    return 0 if end_on.blank? || end_on > TimeKeeper.date_of_record
    hours_per_week
  end


##### Methods below were transferred from EDI DB system
##### TODO: verify utility and improve names

  # Change this to spaceship operator
  def same_as?(other)
    amount == other.amount \
      && kind == other.kind \
      && frequency == other.frequency \
      && start_on == other.start_on \
      && end_on == other.end_on \
      && is_projected == other.is_projected \
      && submitted_at == other.submitted_at
  end

  def <=>(other)
    [amount, kind, frequency, start_on, end_on, is_projected] ==
    [other.amount, other.kind, other.frequency, other.start_on, other.end_on, other.is_projected]
  end


  def self.from_income_request(income_data)
    income = Income.new(
      amount: (income_data[:amount] * 100).to_i,
      kind: income_data[:kind],
      frequency: income_data[:frequency],
      start_on: income_data[:start_on],
      end_on: income_data[:end_on],
      is_projected: income_data[:is_projected],
      submitted_at: income_data[:submitted_at])

  end

  def hours_worked_per_week
  end

private

  def set_submission_timestamp
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
  end

  def start_on_must_precede_end_on
    return unless start_on.present? && end_on.present?
    errors.add(:end_on, "can't occur before start on date") if end_on < start_on
  end

end
