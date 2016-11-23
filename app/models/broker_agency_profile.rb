class BrokerAgencyProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

  MARKET_KINDS = %W[individual shop both]

  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }


  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :primary_broker_role_id, type: BSON::ObjectId
  field :default_general_agency_profile_id, type: BSON::ObjectId

  field :languages_spoken, type: Array, default: ["en"] # TODO
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :home_page, :home_page=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_fake_fein, :is_fake_fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  accepts_nested_attributes_for :inbox

  has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
  accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :market_kind, :entity_kind #, :primary_broker_role_id

  validates :corporate_npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: true

  validates :market_kind,
    inclusion: { in: MARKET_KINDS, message: "%{value} is not a valid practice area" },
    allow_blank: false

  validates :entity_kind,
    inclusion: { in: Organization::ENTITY_KINDS[0..3], message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  after_initialize :build_nested_models

  scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
  scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }


  # has_many employers
  def employer_clients
    return unless (MARKET_KINDS - ["individual"]).include?(market_kind)
    return @employer_clients if defined? @employer_clients
    @employer_clients = EmployerProfile.find_by_broker_agency_profile(self)
  end

  # TODO: has_many families
  def family_clients
    return unless (MARKET_KINDS - ["shop"]).include?(market_kind)
    return @family_clients if defined? @family_clients
    @family_clients = Family.by_broker_agency_profile_id(self.id)
  end

  # has_one primary_broker_role
  def primary_broker_role=(new_primary_broker_role = nil)
    if new_primary_broker_role.present?
      raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker_role._id
    else
      unset("primary_broker_role_id")
    end
    @primary_broker_role = new_primary_broker_role
  end

  def primary_broker_role
    return @primary_broker_role if defined? @primary_broker_role
    @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  # has_many active broker_roles
  def active_broker_roles
    # return @active_broker_roles if defined? @active_broker_roles
    @active_broker_roles = BrokerRole.find_active_by_broker_agency_profile(self)
  end

  # has_many candidate_broker_roles
  def candidate_broker_roles
    # return @candidate_broker_roles if defined? @candidate_broker_roles
    @candidate_broker_roles = BrokerRole.find_candidates_by_broker_agency_profile(self)
  end

  # has_many inactive_broker_roles
  def inactive_broker_roles
    # return @inactive_broker_roles if defined? @inactive_broker_roles
    @inactive_broker_roles = BrokerRole.find_inactive_by_broker_agency_profile(self)
  end

  # alias for broker_roles
  def writing_agents
    active_broker_roles
  end

  # alias for broker_roles - deprecate
  def brokers
    active_broker_roles
  end

  def legal_name
    organization.legal_name
  end

  def phone
    office = organization.primary_office_location
    office && office.phone.to_s
  end

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def is_active?
    self.is_approved?
  end

  def languages
    if languages_spoken.any?
      return languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
    end
  end

  def linked_employees
    employer_profiles = EmployerProfile.find_by_broker_agency_profile(self)
    emp_ids = employer_profiles.map(&:id)
    linked_employees = Person.where(:'employee_roles.employer_profile_id'.in => emp_ids)
  end

  def families
    linked_active_employees = linked_employees.select{ |person| person.has_active_employee_role? }
    employee_families = linked_active_employees.map(&:primary_family).to_a
    consumer_families = Family.by_broker_agency_profile_id(self.id).to_a
    families = (consumer_families + employee_families).uniq
    families.sort_by{|f| f.primary_applicant.person.last_name}
  end

  def default_general_agency_profile=(new_default_general_agency_profile = nil)
    if new_default_general_agency_profile.present?
      raise ArgumentError.new("expected GeneralAgencyProfile class") unless new_default_general_agency_profile.is_a? GeneralAgencyProfile
      self.default_general_agency_profile_id = new_default_general_agency_profile.id
    else
      unset("default_general_agency_profile_id")
    end
    @default_general_agency_profile = new_default_general_agency_profile
  end

  def default_general_agency_profile
    return @default_general_agency_profile if defined? @default_general_agency_profile
    @default_general_agency_profile = GeneralAgencyProfile.find(self.default_general_agency_profile_id) if default_general_agency_profile_id.present?
  end

  ## Class methods
  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.broker_agency_profile }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      list_embedded Organization.exists(broker_agency_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      organizations.size > 0 ? organizations.first.broker_agency_profile : nil
    end
  end

  aasm do #no_direct_assignment: true do
    state :is_applicant, initial: true
    state :is_approved
    state :is_rejected
    state :is_suspended
    state :is_closed

    event :approve do
      transitions from: [:is_applicant, :is_suspended], to: :is_approved
    end

    event :reject do
      transitions from: :is_applicant, to: :is_rejected
    end

    event :suspend do
      transitions from: [:is_applicant, :is_approved], to: :is_suspended
    end

    event :close do
      transitions from: [:is_approved, :is_suspended], to: :is_closed
    end
  end

private

  def build_nested_models
    build_inbox if inbox.nil?
  end
end
