# frozen_string_literal: true

class EligibilityDetermination
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :tax_household

  SOURCE_KINDS = %w[Curam Admin Renewals].freeze

  CSR_KINDS = %w[csr_100 csr_94 csr_87 csr_73].freeze

  CSR_PERCENT_VALUES = %w[100 94 87 73 0 -1].freeze

  CSR_KIND_TO_PLAN_VARIANT_MAP = {
    'csr_0' => '01',
    'csr_94' => '06',
    'csr_87' => '05',
    'csr_73' => '04',
    'csr_100' => '02',
    'limited' => '03'
  }.freeze

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
  field :csr_eligibility_kind, type: String, default: 'csr_0'

  field :determined_at, type: DateTime

  # DEPRECATED - use determined_at. See ticket 42408
  field :determined_on, type: DateTime

  # Source will tell who determined / redetermined eligibility. Eg: Curam or Admin
  field :source, type: String

end
