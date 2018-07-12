class Quote
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies
  include AASM

  extend Mongorder


  PLAN_OPTION_KINDS = [:single_plan, :single_carrier, :metal_level]
  field :quote_name, type: String, default: "Sample Quote"
  #field :plan_year, type: Integer, default: TimeKeeper.date_of_record.year
  def plan_year
    start_on.year
  end
  
  field :start_on, type: Date
  field :broker_role_id, type: BSON::ObjectId


  field :claim_code, type: String
  field :employer_name, type: String
  field :employer_type, type: String
  field :employer_profile_id, type: BSON::ObjectId

  associated_with_one :broker_role, :broker_role_id, "BrokerRole"
  associated_with_one :employer_profile, :employer_profile_id, "EmployerProfile"



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
  index({"quote_benefit_groups._id" => 1}, { unique: true })

  scope :datatable_search, ->(query) { where(quote_name: ::Regexp.new(::Regexp.escape(query), true)) }
  scope :by_client_employer_type, -> { where(employer_type: 'client') }
  scope :by_prospect_employer_type, -> { where(employer_type: 'prospect') }

  after_create :update_default_benefit_group

  def self.default_search_order
    [[:quote_name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = ::Regexp.compile(::Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"quote_name" => search_rex}
      ])
    }
  end

  def can_quote_be_published?
    all_households_have_benefit_groups? && all_benefit_groups_have_plans? && is_quote_eligible?
  end

  def all_households_have_benefit_groups?
    quote_households.map(&:quote_benefit_group_id).map(&:to_s).include?(nil) ? false : true
  end

  def all_benefit_groups_have_plans?
    quote_benefit_groups.reject{ |q| !q.is_assigned? }.map(&:plan).include?(nil) ? false : true
  end

  def min_employer_contribution
    unless quote_benefit_groups.size == 0
      quote_benefit_groups.reject{ |q| !q.is_assigned? }.map do |qbg|
        qbg.relationship_benefit_for("employee")
      end.map(&:premium_pct).min
    end
  end

  def is_quote_eligible?
    quote_eligibility_warnings.blank?
  end

  def quote_warnings
    if !is_quote_eligible?
      quote_eligibility_warnings.each_pair(){ |k, v| self.errors.add(:base, v)}
    end
  end

  def quote_eligibility_warnings
    warnings = {}
    unless start_on.yday == 1
      if quote_benefit_groups.size > 0 && (min_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
        warnings.merge!({min_employer_contribution: "Employer contribution percent toward employee premium (#{min_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)"})
      end
    end
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

  def set_employer_claim_code
    self.claim_code = employer_claim_code
    self.save!
  end

  def clone
    q = super
    is_copy, root_of_copied_name = *(q.quote_name.match(/(.+)\(\d+\)$/))
    name = root_of_copied_name || q.quote_name
    max_copies = 0
    Quote.where(broker_role_id: q.broker_role_id).each{|quote|
      matched, matched_name,match_count = *(quote.quote_name.match /(.+)\((\d+)\)$/)
      max_copies = match_count.to_i if matched_name == name && ((match_count.to_i) > max_copies)
    }
   q.quote_name = "#{name}(#{max_copies+1})"
   q.aasm_state = 'draft'
   q.claim_code = nil
   q.quote_benefit_groups.each {|bg| bg._id = BSON::ObjectId.new}
   q.save
   q
 end

  aasm do
    state :draft, initial: true
    state :published
    state :claimed

    event :publish do
      transitions from: :draft, to: :published, :guard => "can_quote_be_published?", after: :set_employer_claim_code
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

  def update_default_benefit_group
    qbg=quote_benefit_groups.first
    quote_households.each do |qoute_household|
      qoute_household.update_attributes(:quote_benefit_group_id => qbg.id)
    end
  end

end
