class FinancialAssistance::Deduction
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application, class_name: "::FinancialAssistance::Application"

  TITLE_SIZE_RANGE = 3..30
  FREQUENCY_KINDS = %W(biweekly daily half_yearly monthly quarterly weekly yearly)

  KINDS = %W(
      alimony_paid
      deductable_part_of_self_employment_taxes
      domestic_production_activities
      penalty_on_early_withdrawel_of_savings
      educator_expenses
      rent_or_royalties
      self_employment_sep_simple_and_qualified_plans
      self_employed_health_insurance
      moving_expenses
      health_savings_account
      reservists_performing_artists_and_fee_basis_government_official_expenses
    )

  field :title, type: String
  field :kind, as: :deduction_type, type: String
  field :amount, type: Money, default: 0.0
  field :start_on, type: Date
  field :end_on, type: Date
  field :frequency_kind, type: String
  field :submitted_at, type: DateTime

  validates_length_of :title, 
                      in: TITLE_SIZE_RANGE, 
                      allow_nil: true,
                      message: "pick a name length between #{TITLE_SIZE_RANGE}"

  validates :amount,          presence: true,
                              numericality: { greater_than: 0, message: "%{value} must be greater than $0" }
  validates :kind,            presence: true,
                              inclusion: { in: KINDS, message: "%{value} is not a valid deduction type" }
  validates :frequency_kind,  presence: true,
                              inclusion: { in: FREQUENCY_KINDS, message: "%{value} is not a valid frequency" }
  validates :start_on,        presence: true

  validate :start_on_must_precede_end_on

  before_create :set_submission_timestamp

private

  def set_submission_timestamp
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
  end

  def start_on_must_precede_end_on
    return unless start_on.present? && end_on.present?
    errors.add(:end_on, "can't occur before start on date") if end_on < start_on
  end


end
