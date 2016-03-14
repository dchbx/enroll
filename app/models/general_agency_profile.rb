class GeneralAgencyProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include AgencyProfile

  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :languages_spoken, type: Array, default: ["en"] # TODO
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean
  field :aasm_state, type: String, default: 'is_applicant'
  field :aasm_state_set_on, type: Date

  # for organizations
  embedded_in :organization
  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :home_page, :home_page=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  has_many :general_agency_contacts, class_name: "Person", inverse_of: :general_agency_contact
  accepts_nested_attributes_for :general_agency_contacts, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :market_kind, :entity_kind

  validates :corporate_npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: true

  validates :market_kind,
    inclusion: { in: MARKET_KINDS, message: "%{value} is not a valid market kind" },
    allow_blank: false

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  accepts_nested_attributes_for :inbox
  after_initialize :build_nested_models

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def general_agency_staff_roles
    Person.where("general_agency_staff_roles.general_agency_profile_id" => BSON::ObjectId.from_string(self.id))
  end

  # has_many active general_agency_roles
  #def active_general_agency_roles
  #  @active_general_agency_roles = GeneralAgencyRole.find_active_by_broker_agency_profile(self)
  #end

  ## has_many candidate_general_agency_roles
  #def candidate_general_agency_roles
  #  @candidate_general_agency_roles = GeneralAgencyRole.find_candidates_by_broker_agency_profile(self)
  #end

  ## has_many inactive_general_agency_roles
  #def inactive_general_agency_roles
  #  # return @inactive_general_agency_roles if defined? @inactive_general_agency_roles
  #  @inactive_general_agency_roles = GeneralAgencyRole.find_inactive_by_broker_agency_profile(self)
  #end

  # alias for general_agency_roles
  #def writing_agents
  #  active_general_agency_roles
  #end

  def legal_name
    organization.legal_name
  end

  def phone
    office = organization.primary_office_location
    office && office.phone.to_s
  end

  def languages
    if languages_spoken.any?
      return languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
    end
  end

  def linked_employees
    employer_profiles = EmployerProfile.find_by_general_agency_profile(self)
    emp_ids = employer_profiles.map(&:id)
    linked_employees = Person.where(:'employee_roles.employer_profile_id'.in => emp_ids)
  end

  def families
    employee_families = linked_employees.map(&:primary_family).to_a
    consumer_families = Family.by_general_agency_profile(self).to_a
    families = (consumer_families + employee_families).uniq
    families.sort_by{|f| f.primary_applicant.person.last_name}
  end

  def employer_clients_count
    employer_clients.present? ? employer_clients.count : 0
  end

  def current_state
    aasm_state.humanize.titleize
  end

  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.general_agency_profile }
    end

    def all
      list_embedded Organization.exists(general_agency_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("general_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      organizations.size > 0 ? organizations.first.general_agency_profile : nil
    end
  end

  aasm do
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
