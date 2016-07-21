class BrokerRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers

  PROVIDER_KINDS = %W[broker assister]
  BROKER_UPDATED_EVENT_NAME = "acapi.info.events.broker.updated"

  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }

  BROKER_CARRIER_APPOINTMENTS = {:aetna_health_inc => nil,
    :aetna_life_insurance_company => nil,
     :carefirst_bluechoice_inc => nil,
     :group_hospitalization_and_medical_services_inc => nil,
     :kaiser_foundation => nil,
     :optimum_choice => nil,
     :united_health_care_insurance => nil,
     :united_health_care_mid_atlantic => nil}

  embedded_in :person

  field :aasm_state, type: String

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  field :market_kind, type: String
  field :languages_spoken, type: Array, default: ["en"]
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean
  field :license, type: Boolean
  field :training, type: Boolean
  field :carrier_appointments, type: Hash , default: BROKER_CARRIER_APPOINTMENTS

  embeds_many :workflow_state_transitions, as: :transitional
  embeds_many :favorite_general_agencies, cascade_callbacks: true

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person, :workflow_state_transitions

  after_initialize :initial_transition

  validates_presence_of :npn, :provider_kind

  validates :npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: false

  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }

  scope :active,    ->{ any_in(aasm_state: ["applicant", "active", "broker_agency_pending"]) }
  scope :inactive,  ->{ any_in(aasm_state: ["denied", "decertified", "broker_agency_declined", "broker_agency_terminated"]) }

  def self.by_npn(broker_npn)
    person_records = Person.by_broker_role_npn(broker_npn)
    return [] unless person_records.any?
    person_records.select do |pr|
      pr.broker_role.present? &&
        (pr.broker_role.npn == broker_npn)
    end.map(&:broker_role)
  end

  def search_favorite_general_agencies(general_agency_profile_id)
    favorite_general_agencies.where(general_agency_profile_id: general_agency_profile_id)
  end

  def included_in_favorite_general_agencies?(general_agency_profile_id)
    favorite_general_agencies.present? && favorite_general_agencies.map(&:general_agency_profile_id).include?(general_agency_profile_id)
  end

  def email_address
    return nil unless email.present?
    email.address
  end

  def parent
    # raise "undefined parent: Person" unless self.person?
    self.person
  end

  # belongs_to broker_agency_profile
  def broker_agency_profile=(new_broker_agency)
    if new_broker_agency.nil?
      self.broker_agency_profile_id = nil
    else
      raise ArgumentError.new("expected BrokerAgencyProfile class") unless new_broker_agency.is_a? BrokerAgencyProfile
      self.broker_agency_profile_id = new_broker_agency._id
      @broker_agency_profile = new_broker_agency
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(broker_agency_profile_id) if has_broker_agency_profile?
  end

  def has_broker_agency_profile?
    self.broker_agency_profile_id.present?
  end

  def address=(new_address)
    parent.addresses << new_address
  end

  def address
    parent.addresses.detect { |addr| addr.kind == "work" }
  end

  def phone=(new_phone)
    parent.phones << new_phone
  end

  def phone
    parent.phones.detect { |phone| phone.kind == "work" } || broker_agency_profile.phone rescue ""
  end

  def email=(new_email)
    parent.emails << new_email
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  ## Class methods
  class << self

    def find(id)
      return nil if id.blank?
      people = Person.where("broker_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_role : nil
    end

    def find_by_npn(npn_value)
      person = Person.where("broker_role.npn" => npn_value)
      person.first.broker_role unless person.blank?
    end

    def list_brokers(person_list)
      person_list.reduce([]) { |brokers, person| brokers << person.broker_role }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      # criteria = Mongoid::Criteria.new(Person)
      list_brokers(Person.exists(broker_role: true))
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find_by_broker_agency_profile(broker_agency_profile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless broker_agency_profile.is_a?(BrokerAgencyProfile)
      # list_brokers(Person.where("broker_role.broker_agency_profile_id" => profile._id))
      people = (Person.where("broker_role.broker_agency_profile_id" => broker_agency_profile.id))
      people.collect(&:broker_role)
    end

    def find_candidates_by_broker_agency_profile(broker_agency_profile)
      people = Person.where(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id)\
                            .any_in(:"broker_role.aasm_state" => ["applicant", "broker_agency_pending"])
      people.collect(&:broker_role)
    end

    def find_active_by_broker_agency_profile(broker_agency_profile)
      people = Person.and(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id,
                          :"broker_role.aasm_state"  => "active")
      people.collect(&:broker_role)
    end

    def find_inactive_by_broker_agency_profile(broker_agency_profile)
      people = Person.where(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id)\
                            .any_in(:"broker_role.aasm_state" => ["denied", "decertified", "broker_agency_declined", "broker_agency_terminated"])
      people.collect(&:broker_role)
    end

    def agency_ids_for_active_brokers
      Person.collection.raw_aggregate([
        {"$match" => {"broker_role.aasm_state" => "active"}},
        {"$group" => {"_id" => "$broker_role.broker_agency_profile_id"}}
      ]).map do |record|
        record["_id"]
      end
    end

    def brokers_matching_search_criteria(search_str)
      Person.exists(broker_role: true).search_first_name_last_name_npn(search_str).where("broker_role.aasm_state" => "active")
    end

    def agencies_with_matching_broker(search_str)
      broker_role_ids = brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:id)

      Person.collection.raw_aggregate([
        {"$match" => {"broker_role.aasm_state" => "active", "broker_role._id" => { "$in" => broker_role_ids}}},
        {"$group" => {"_id" => "$broker_role.broker_agency_profile_id"}}
      ]).map do |record|
        record["_id"]
      end
    end
  end

  aasm do
    state :applicant, initial: true
    state :active
    state :denied
    state :decertified
    state :broker_agency_pending
    state :broker_agency_declined
    state :broker_agency_terminated

    event :approve, :after => [:record_transition, :send_invitation, :notify_updated] do
      transitions from: :applicant, to: :active, :guard => :is_primary_broker?
      transitions from: :broker_agency_pending, to: :active, :guard => :is_primary_broker?
      transitions from: :applicant, to: :broker_agency_pending
    end

    event :pending , :after =>[:record_transition, :notify_updated, :notify_broker_pending] do
      transitions from: :applicant, to: :broker_agency_pending, :guard => :is_primary_broker?
    end

    event :broker_agency_accept, :after => [:record_transition, :send_invitation, :notify_updated] do
      transitions from: :broker_agency_pending, to: :active
    end

    event :broker_agency_decline, :after => :record_transition do
      transitions from: :broker_agency_pending, to: :broker_agency_declined
    end

    event :broker_agency_terminate, :after => :record_transition do
      transitions from: :active, to: :broker_agency_terminated
    end

    event :deny, :after => [:record_transition, :notify_broker_denial]  do
      transitions from: :applicant, to: :denied
      transitions from: :broker_agency_pending, to: :denied
    end

    event :decertify, :after => :record_transition  do
      transitions from: :active, to: :decertified
    end

    # Attempt to achieve or return to good standing with HBX
    event :reapply, :after => :record_transition  do
      transitions from: [:applicant, :decertified, :denied, :broker_agency_declined], to: :applicant
    end

    # Moves between broker agency organizations that don't require HBX re-certification
    event :transfer, :after => :record_transition  do
      transitions from: [:active, :broker_agency_pending, :broker_agency_terminated], to: :applicant
    end
  end

  def notify_updated
    notify(BROKER_UPDATED_EVENT_NAME, { :broker_id => self.npn } )
  end


  private

  def is_primary_broker?
    return false unless broker_agency_profile
    broker_agency_profile.primary_broker_role == self
  end

  def initial_transition
    return if workflow_state_transitions.size > 0
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: nil,
      to_state: aasm.to_state || "applicant"
      )
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  def send_invitation
    if active?
      Invitation.invite_broker!(self)
    end
  end

  def notify_broker_denial
    UserMailer.broker_denied_notification(self).deliver_now
  end

  def notify_broker_pending
    unchecked_carriers = self.carrier_appointments.select { |k,v| k if v != "true"}
    UserMailer.broker_pending_notification(self,unchecked_carriers).deliver_now if unchecked_carriers.present?  || !self.training
  end

  def applicant?
    aasm_state == 'applicant'
  end

  def active?
    aasm_state == 'active'
  end

  def agency_pending?
    aasm_state == 'broker_agency_pending'
  end

  def approved_or_pending?
    aasm_state == 'active'
  end

  def latest_transition_time
    if self.workflow_state_transitions.any?
      self.workflow_state_transitions.first.transition_at
    end
  end

  def current_state
    aasm_state.gsub(/\_/,' ').camelcase
  end
end
