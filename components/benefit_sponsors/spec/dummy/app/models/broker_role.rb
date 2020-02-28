class BrokerRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  PROVIDER_KINDS = %W[broker assister]
  BROKER_UPDATED_EVENT_NAME = "acapi.info.events.broker.updated"

  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }

  DC_BROKER_CARRIER_APPOINTMENTS = {
    "Aetna Health Inc" => nil,
    "Aetna Life Insurance Company" => nil,
    "Carefirst Bluechoice Inc" => nil,
    "Group Hospitalization and Medical Services Inc" => nil,
    "Kaiser Foundation" => nil,
    "Optimum Choice" => nil,
    "United Health Care Insurance" => nil,
    "United Health Care Mid Atlantic" => nil
  }.freeze

  CCA_BROKER_CARRIER_APPOINTMENTS = {
    "Altus" => nil,
    "Blue Cross Blue Shield MA" => nil,
    "Boston Medical Center Health Plan" => nil,
    "Delta" => nil,
    "FCHP" => nil,
    "Guardian" => nil,
    "Health New England" => nil,
    "Harvard Pilgrim Health Care" => nil,
    "Minuteman Health" => nil,
    "Neighborhood Health Plan" => nil,
    "Tufts Health Plan Direct" => nil,
    "Tufts Health Plan Premier" => nil
  }.freeze

  embedded_in :person

  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  field :market_kind, type: String
  field :languages_spoken, type: Array, default: ["en"]
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean

  field :aasm_state, type: String

  validates_presence_of :npn, :provider_kind

  validates :npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: false

  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }

  def broker_agency_profile=(new_broker_agency)
    if new_broker_agency.nil?
      self.benefit_sponsors_broker_agency_profile_id = nil
    else
      raise ArgumentError.new("expected BenefitSponsors::Organizations::BrokerAgencyProfile class") unless new_broker_agency.is_a? BenefitSponsors::Organizations::BrokerAgencyProfile
      self.benefit_sponsors_broker_agency_profile_id = new_broker_agency._id
      @broker_agency_profile = new_broker_agency
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => benefit_sponsors_broker_agency_profile_id).first.broker_agency_profile if has_broker_agency_profile?
  end

  def has_broker_agency_profile?
    self.benefit_sponsors_broker_agency_profile_id.present?
  end

  def parent
    self.person
  end

  def phone
    parent.phones.where(:kind.in => ["main", "phone main"]).first || broker_agency_profile.phone || parent.phones.where(kind: "work").first rescue ""
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  aasm do
    state :applicant, initial: true
    state :active
    state :denied
    state :decertified
    state :broker_agency_pending
    state :broker_agency_declined
    state :broker_agency_terminated
    state :application_extended

    event :approve, :after => [:record_transition, :send_invitation, :notify_updated] do
      transitions from: [:applicant, :application_extended], to: :active, :guard => :is_primary_broker?
      transitions from: :broker_agency_pending, to: :active, :guard => :is_primary_broker?
      transitions from: :applicant, to: :broker_agency_pending
    end

    event :pending , :after =>[:record_transition, :notify_updated, :notify_broker_pending] do
      transitions from: :applicant, to: :broker_agency_pending, :guard => :is_primary_broker?
      transitions from: :broker_agency_pending, to: :broker_agency_pending, :guard => :is_primary_broker?
    end

    event :broker_agency_accept, :after => [:record_transition, :send_invitation, :notify_updated] do
      transitions from: :broker_agency_pending, to: :active
    end

    event :broker_agency_decline, :after => :record_transition do
      transitions from: :broker_agency_pending, to: :broker_agency_declined
    end

    event :broker_agency_terminate, :after => [:record_transition, :remove_broker_assignments] do
      transitions from: :active, to: :broker_agency_terminated
    end

    event :deny, :after => [:record_transition, :notify_broker_denial]  do
      transitions from: :applicant, to: :denied
      transitions from: :broker_agency_pending, to: :denied
    end

    event :decertify, :after => [:record_transition, :remove_broker_assignments]  do
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

    # Not currently supported in UI.   Datafix only person.broker_role.recertify! refs #12398
    event :recertify, :after => :record_transition do
      transitions from: :decertified, to: :active
    end

    # Extends the broker application denial time
    event :extend_application, :after => :record_transition do
      transitions from: [:broker_agency_pending, :denied], to: :application_extended
    end
  end
  
  class << self
    def find(id)
      return nil if id.blank?
      people = Person.where("broker_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_role : nil
    end

    def brokers_matching_search_criteria(search_str)
      Person.exists(broker_role: true).search_first_name_last_name_npn(search_str).where("broker_role.aasm_state" => "active")
    end

    def agencies_with_matching_broker(search_str)
      broker_role_ids = brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:id)
      if brokers_matching_search_criteria(search_str).map(&:broker_role).detect{|b|b.benefit_sponsors_broker_agency_profile_id}.present?
        Person.collection.raw_aggregate([
                                            {"$match" => {"broker_role.aasm_state" => "active", "broker_role._id" => { "$in" => broker_role_ids}}},
                                            {"$group" => {"_id" => "$broker_role.benefit_sponsors_broker_agency_profile_id"}}
                                        ]).map do |record|
          record["_id"]
        end
      else
        Person.collection.raw_aggregate([
                                            {"$match" => {"broker_role.aasm_state" => "active", "broker_role._id" => { "$in" => broker_role_ids}}},
                                            {"$group" => {"_id" => "$broker_role.broker_agency_profile_id"}}
                                        ]).map do |record|
          record["_id"]
        end
      end
    end

  end

  private

  def is_primary_broker?
    return false unless broker_agency_profile
    broker_agency_profile.primary_broker_role == self
  end

  def record_transition
  end

end