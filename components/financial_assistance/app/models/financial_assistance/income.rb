# frozen_string_literal: true

module FinancialAssistance
  class Income
    include Mongoid::Document
    include Mongoid::Timestamps

    before_create :set_submission_timestamp

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'
    embeds_one :employer_address, class_name: 'FinancialAssistance::Locations::Address', cascade_callbacks: true
    embeds_one :employer_phone, class_name: 'FinancialAssistance::Locations::Phone', cascade_callbacks: true

    TITLE_SIZE_RANGE = (3..30).freeze

    KINDS = %w[
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
    ].freeze

    JOB_INCOME_TYPE_KIND = 'wages_and_salaries'
    NET_SELF_EMPLOYMENT_INCOME_KIND = 'net_self_employment'
    FREQUENCY_KINDS = %w[biweekly daily half_yearly monthly quarterly weekly yearly].freeze

    OTHER_INCOME_TYPE_KIND = {
      alimony_and_maintenance: 'Alimony received',
      capital_gains: 'Capital gains',
      dividend: 'Dividends',
      interest: 'Interest',
      pension_retirement_benefits: 'Pension or retirement',
      rental_and_royalty: 'Rent and royalties',
      unemployment_insurance: 'Unemployment',
      social_security_benefit: 'Social Security',
      american_indian_and_alaskan_native: "American Indian/Alaska Native income",
      employer_funded_disability: 'Employer-funded disability payments',
      estate_trust: 'Estate and trust',
      farming_and_fishing: 'Farming or fishing',
      foreign: 'Foreign income',
      other: 'Other taxable income',
      prizes_and_awards: 'Prizes and awards',
      scholorship_payments: 'Taxable scholarship payments'
    }.freeze

    field :title, type: String
    field :kind, as: :income_type, type: String, default: 'wages_and_salaries'
    field :wage_type, type: String
    field :hours_per_week, type: Integer
    field :amount, type: Money, default: 0.00
    field :amount_tax_exempt, type: Integer, default: 0
    field :frequency_kind, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :is_projected, type: Boolean, default: false
    field :tax_form, type: String
    field :employer_name, type: String
    field :employer_id, type: Integer
    field :has_property_usage_rights, type: Boolean
    field :submitted_at, type: DateTime
    field :workflow, type: Hash, default: { }

    scope :jobs, -> {where(kind: JOB_INCOME_TYPE_KIND)}
    scope :self_employment, -> {where(kind: NET_SELF_EMPLOYMENT_INCOME_KIND)}
    scope :other, -> {where(:kind.nin => [JOB_INCOME_TYPE_KIND, NET_SELF_EMPLOYMENT_INCOME_KIND])}
    scope :of_kind, ->(kind) {where(kind: kind)}

    validates_length_of :title,
                        in: TITLE_SIZE_RANGE,
                        allow_nil: true,
                        message: "pick a name length between #{TITLE_SIZE_RANGE}",
                        on: [:step_1, :submission]

    validates :amount, presence: true,
                       numericality: {
                         greater_than: 0, message: "%<value> must be greater than $0"
                       },
                       on: [:step_1, :submission]

    validates :kind, presence: true,
                     inclusion: {
                       in: KINDS, message: "%<value> is not a valid income type"
                     },
                     on: [:step_1, :submission]

    validates :frequency_kind, presence: true,
                               inclusion: {
                                 in: FREQUENCY_KINDS, message: "%{value} is not a valid frequency"
                               }

    validates :start_on, presence: true, on: [:step_1, :submission]
    validate :start_on_must_precede_end_on

    def hours_worked_per_week
      return 0 if end_on.blank? || end_on > TimeKeeper.date_of_record
      hours_per_week
    end

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
      Income.new(
        amount: (income_data[:amount] * 100).to_i,
        kind: income_data[:kind],
        frequency: income_data[:frequency],
        start_on: income_data[:start_on],
        end_on: income_data[:end_on],
        is_projected: income_data[:is_projected],
        submitted_at: income_data[:submitted_at]
      )
    end

    class << self
      def find(id)
        bson_id = BSON::ObjectId.from_string(id.to_s)
        applications = ::FinancialAssistance::Application.where('applicants.incomes._id' => bson_id)
        return unless applications.size == 1
        applicants = applications.first.applicants.where('incomes._id' => bson_id)
        applicants.size == 1 ? applicants.first.incomes.find(bson_id) : nil
      end
    end

    private

    def set_submission_timestamp
      write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
    end

    def start_on_must_precede_end_on
      return unless start_on.present? && end_on.present?
      errors.add(:end_on, "Date can't occur before start on date") if end_on < start_on
    end
  end
end
