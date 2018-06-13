class GeneralAgencyProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include AgencyProfile
  include Config::AcaModelConcern

  # for market_kind
  MARKET_KINDS = individual_market_is_enabled? ? %W[individual shop both] : %W[shop]
  ALL_MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both - Individual & Family AND Small Business Marketplaces" => "both"
  }
  MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |k,v| MARKET_KINDS.include? v }


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

  embeds_many :documents, as: :documentable
  has_many :general_agency_contacts, class_name: "Person", inverse_of: :general_agency_contact
  accepts_nested_attributes_for :general_agency_contacts, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :market_kind, :entity_kind

  validates :corporate_npn,
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },
    uniqueness: true,
    allow_blank: true

  validates :market_kind,
    inclusion: { in: -> (val) { MARKET_KINDS }, message: "%{value} is not a valid market kind" },
    allow_blank: false

  embeds_many :documents, as: :documentable
  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  accepts_nested_attributes_for :inbox
  after_initialize :build_nested_models

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def general_agency_staff_roles
    Person.where("general_agency_staff_roles.general_agency_profile_id" => BSON::ObjectId.from_string(self.id)).map {|p| p.general_agency_staff_roles.detect {|s| s.general_agency_profile_id == id}}
  end

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
    families = employee_families.uniq.compact
    families.sort_by{|f| f.primary_applicant.person.last_name}
  end

  def employer_clients_count
    employer_clients.present? ? employer_clients.count : 0
  end

  # general_agency should have only one general_agency_staff_role
  def primary_staff
    general_agency_staff_roles.present? ? general_agency_staff_roles.last : nil
  end

  def current_staff_state
    primary_staff.current_state rescue ""
  end

  def current_state
    aasm_state.humanize.titleize
  end

  def applicant?
    aasm_state == "is_applicant"
  end

  def general_agency_hired_notice(employer_profile)
    begin
      ShopNoticesNotifierJob.perform_later(self.id.to_s, "general_agency_hired_notice", employer_profile_id: employer_profile.id.to_s)
    rescue Exception => e
      (Rails.logger.error {"Unable to deliver general_agency_hired_notice to General Agency: #{self.legal_name} due to #{e}"}) unless Rails.env.test?
    end
  end

  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.general_agency_profile }
    end

    def all
      list_embedded Organization.exists(general_agency_profile: true).order_by([:legal_name]).to_a
    end

    def all_by_broker_role(broker_role, options={})
      favorite_general_agency_ids = broker_role.favorite_general_agencies.map(&:general_agency_profile_id) rescue []
      all_ga = if options[:approved_only]
                 all.select{|ga| ga.aasm_state == 'is_approved'}
               else
                 all
               end

      if favorite_general_agency_ids.present?
        all_ga.sort {|ga| favorite_general_agency_ids.include?(ga.id) ? 0 : 1 }
      else
        all_ga
      end
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

    def filter_by(status="is_applicant")
      if status == 'all'
        all
      else
        list_embedded Organization.exists(general_agency_profile: true).where(:'general_agency_profile.aasm_state' => status).order_by([:legal_name]).to_a
      end
    rescue
      []
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
