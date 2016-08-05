class Quote
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies
  include AASM

  extend Mongorder


  PLAN_OPTION_KINDS = [:single_plan, :single_carrier, :metal_level]
  field :quote_name, type: String, default: "Sample Quote"
  field :plan_year, type: Integer, default: TimeKeeper.date_of_record.year
  field :start_on, type: Date
  field :broker_role_id, type: BSON::ObjectId


  field :claim_code, type: String
  associated_with_one :broker_role, :broker_role_id, "BrokerRole"


  # Quote should now support multiple benefit groups
  embeds_many :quote_benefit_groups, cascade_callbacks: true


  embeds_many :quote_households, cascade_callbacks: true


  # accepts_nested_attributes_for
  accepts_nested_attributes_for :quote_households, reject_if: :all_blank
  accepts_nested_attributes_for :quote_benefit_groups, reject_if: :all_blank

  validates_uniqueness_of :claim_code, :case_sensitive => false, :allow_nil => true

  # fields for state machine
  field :aasm_state, type: String
  field :aasm_state_date, type: Date

  field :criteria_for_ui, type: String, default: []

  index({ broker_role_id: 1 })
  index({ broker_role_id: 1, aasm_state: 1 })

  scope :all_broker_quotes,                  -> (broker_role_id) { where(broker_role_id: broker_role_id) }
  scope :draft_quotes,                       -> { where("aasm_state" => 'draft') }
  scope :published_quotes,                   -> { where("aasm_state" => 'published') }
  scope :claimed_quotes,                   -> { where("aasm_state" => 'claimed') }



  def self.default_search_order
    [[:quote_name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = Regexp.compile(Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"quote_name" => search_rex}
      ])
    }
  end

  def published_employee_cost
    plan && roster_employee_cost(plan.id, plan.id)
  end

  def published_employer_cost
    plan && roster_employer_contribution(plan.id, plan.id)
  end

  def can_quote_be_published?
    all_households_have_benefit_groups? && all_benefit_groups_have_plans?
  end

  def all_households_have_benefit_groups?
    quote_households.map(&:quote_benefit_group_id).map(&:to_s).include?(nil) ? false : true
  end

  def all_benefit_groups_have_plans?
    quote_benefit_groups.map(&:plan).include?(nil) ? false : true
  end

  def member_count
    quote_households.map(&:quote_members).inject(:+).count
  end

  def can_edit?
    !(claimed? || published?)
  end

  def is_complete?
    claimed? || published?
  end

  def generate_character
    ascii = rand(36) + 48
    ascii += 39 if ascii >= 58
    ascii.chr.upcase
  end

  def employer_claim_code
     4.times.map{generate_character}.join + '-' + 4.times.map{generate_character}.join
  end

  aasm do
    state :draft, initial: true
    state :published
    state :claimed

    event :publish do
      transitions from: :draft, to: :published, :guard => "can_quote_be_published?"
    end

    event :claim do
      transitions from: :published, to: :claimed
    end
  end

  class << self

    def claim_code_status?(quote_claim_code)
      claim_code = Quote.where("claim_code" => quote_claim_code).first
      if claim_code.nil?
        return "invalid"
      else
        return claim_code.aasm_state
      end
    end

  end

end
