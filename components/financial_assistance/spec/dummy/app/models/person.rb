# frozen_string_literal: true

# rubocop:disable all

class Person
  include Config::AcaModelConcern
  include Config::SiteModelConcern
  include Config::ContactCenterModelConcern
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Ssn
  include Mongoid::Attributes::Dynamic
  # include SponsoredBenefits::Concerns::Ssn
  # include SponsoredBenefits::Concerns::Dob

  # include Notify
  include UnsetableSparseFields
  # include FullStrippedNames
  # include ::BenefitSponsors::Concerns::Observable
  # include SponsoredBenefits::Concerns::Dob
  # include LegacyVersioningRecords

  # verification history tracking
  # include Mongoid::History::Trackable

  # extend Mongorder
  # validates_with Validations::DateRangeValidator

  GENDER_KINDS = %w[male female].freeze

  IDENTIFYING_INFO_ATTRIBUTES = %w[first_name last_name ssn dob].freeze
  ADDRESS_CHANGE_ATTRIBUTES = %w[addresses phones emails].freeze
  RELATIONSHIP_CHANGE_ATTRIBUTES = %w[person_relationships].freeze

  PERSON_CREATED_EVENT_NAME = "acapi.info.events.individual.created"
  PERSON_UPDATED_EVENT_NAME = "acapi.info.events.individual.updated"
  VERIFICATION_TYPES = ['Social Security Number', 'American Indian Status', 'Citizenship', 'Immigration status'].freeze

  NON_SHOP_ROLES = ['Individual','Coverall'].freeze

  field :hbx_id, type: String
  field :name_pfx, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String
  field :full_name, type: String
  field :alternate_name, type: String

  field :encrypted_ssn, type: String
  field :gender, type: String
  field :dob, type: Date

  # Sub-model in-common attributes
  field :date_of_death, type: Date
  field :dob_check, type: Boolean

  field :is_incarcerated, type: Boolean

  field :is_disabled, type: Boolean
  field :ethnicity, type: Array
  field :race, type: String
  field :tribal_id, type: String

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String

  field :no_dc_address, type: Boolean, default: false
  field :is_homeless, type: Boolean, default: false
  field :is_temporarily_out_of_state, type: Boolean, default: false
  field :is_moving_to_state, type: Boolean, default: false

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :no_ssn, type: String #ConsumerRole TODO TODOJF
  field :is_physically_disabled, type: Boolean


  delegate :is_applying_coverage, to: :consumer_role, allow_nil: true

  # Login account
  belongs_to :user, inverse_of: :person, optional: true

  belongs_to :employer_contact,
             class_name: "EmployerProfile",
             inverse_of: :employer_contacts,
             index: true,
             optional: true

  belongs_to :broker_agency_contact,
             class_name: "BrokerAgencyProfile",
             inverse_of: :broker_agency_contacts,
             index: true,
             optional: true

  belongs_to :general_agency_contact,
             class_name: "GeneralAgencyProfile",
             inverse_of: :general_agency_contacts,
             index: true,
             optional: true

  embeds_one :consumer_role, cascade_callbacks: true, validate: true
  embeds_one :resident_role, cascade_callbacks: true, validate: true
  embeds_many :individual_market_transitions, cascade_callbacks: true, validate: true, class_name: "::IndividualMarketTransition"

  embeds_one :broker_role, cascade_callbacks: true, validate: true
  embeds_one :hbx_staff_role, cascade_callbacks: true, validate: true
  #embeds_one :responsible_party, cascade_callbacks: true, validate: true # This model does not exist.

  embeds_one :csr_role, cascade_callbacks: true, validate: true
  embeds_one :assister_role, cascade_callbacks: true, validate: true
  embeds_one :inbox, as: :recipient

  embeds_many :employer_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :employee_roles, cascade_callbacks: true, validate: true
  embeds_many :general_agency_staff_roles, cascade_callbacks: true, validate: true

  embeds_many :person_relationships, cascade_callbacks: true, validate: true, class_name: "::PersonRelationship"
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true
  embeds_many :documents, as: :documentable
  embeds_many :verification_types, cascade_callbacks: true, validate: true, class_name: "::VerificationType"

  attr_accessor :effective_date

  attr_accessor :effective_date

  accepts_nested_attributes_for :consumer_role, :resident_role, :broker_role, :hbx_staff_role,
                                :person_relationships, :employee_roles, :phones, :employer_staff_roles

  accepts_nested_attributes_for :phones, :reject_if => proc { |addy| addy[:full_phone_number].blank? }, allow_destroy: true
  accepts_nested_attributes_for :addresses, :reject_if => proc { |addy| addy[:address_1].blank? && addy[:city].blank? && addy[:state].blank? && addy[:zip].blank? }, allow_destroy: true
  accepts_nested_attributes_for :emails, :reject_if => proc { |addy| addy[:address].blank? }, allow_destroy: true

  validates_presence_of :first_name, :last_name
  validate :date_functional_validations
  validate :no_changing_my_user, :on => :update

  validates :encrypted_ssn, uniqueness: true, allow_blank: true

  validate :is_ssn_composition_correct?

  validate :is_only_one_individual_role_active?

  validates :gender,
            allow_blank: true,
            inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }

  before_save :generate_hbx_id
  before_save :update_full_name
  before_save :strip_empty_fields

  #after_save :generate_family_search
  after_create :create_inbox

  # add_observer ::BenefitSponsors::Observers::EmployerStaffRoleObserver.new, :contact_changed?

  index({hbx_id: 1}, {sparse: true, unique: true})
  index({user_id: 1}, {sparse: true, unique: true})

  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name: 1})
  index({first_name: 1, last_name: 1, hbx_id: 1, encrypted_ssn: 1}, {name: "person_searching_index"})

  index({encrypted_ssn: 1}, {sparse: true, unique: true})
  index({dob: 1}, {sparse: true})
  index({dob: 1, encrypted_ssn: 1})

  index({hbx_id: 1, encrypted_ssn: 1}, {name: "person_search_hash_ssn_hbx_id"})
  index({last_name: 1, dob: 1}, {sparse: true})

  index({last_name: "text", first_name: "text", full_name: "text"}, {name: "person_search_text_index"})

  # Broker child model indexes
  index({"broker_role._id" => 1})
  index({"broker_role.provider_kind" => 1})
  index({"broker_role.broker_agency_id" => 1})
  index({"broker_role.benefit_sponsors_broker_agency_profile_id" => 1})
  index({"broker_role.npn" => 1}, {sparse: true, unique: true})

  index({"general_agency_staff_roles.npn" => 1}, {sparse: true})
  index({"general_agency_staff_roles.is_primary" => 1})
  index({"general_agency_staff_roles.benefit_sponsors_general_agency_profile_id" => 1}, {sparse: true})

  index({"first_name" => 1, "last_name" => 1, "broker_role.npn" => 1}, {name: "first_name_last_name_broker_npn_search"})
  index({"first_name" => 1, "last_name" => 1, "general_agency_staff_roles.npn" => 1}, {name: "first_name_last_name_ga_npn_search"})

  index({
          "general_agency_staff_roles.benefit_sponsors_general_agency_profile_id" => 1,
          "general_agency_staff_roles.is_primary" => 1
        }, {name: "agency_search_by_id_and_is_primary"})

  # Employer role index
  index({"employer_staff_roles._id" => 1})
  index({"employer_staff_roles.employer_profile_id" => 1})
  index({"employer_staff_roles.benefit_sponsor_employer_profile_id" => 1})

  # Consumer child model indexes
  index({"consumer_role._id" => 1})
  index({"consumer_role.aasm_state" => 1})
  index({"consumer_role.is_active" => 1})

  # Employee child model indexes
  index({"employee_roles._id" => 1})
  index({"employee_roles.employer_profile_id" => 1})
  index({"employee_roles.census_employee_id" => 1})
  index({"employee_roles.benefit_group_id" => 1})
  index({"employee_roles.is_active" => 1})

  # HbxStaff child model indexes
  index({"hbx_staff_role._id" => 1})
  index({"hbx_staff_role.is_active" => 1})

  # PersonRelationship child model indexes
  index({"person_relationship.relative_id" =>  1})

  index({"hbx_employer_staff_role._id" => 1})

  #index({"hbx_responsible_party_role._id" => 1})

  index({"hbx_csr_role._id" => 1})
  index({"hbx_assister._id" => 1})

  index(
    {"broker_agency_staff_roles._id" => 1},
    {name: "person_broker_agency_staff_role_id_search"}
  )

  scope :all_consumer_roles,          -> { exists(consumer_role: true) }
  scope :all_resident_roles,          -> { exists(resident_role: true) }
  scope :all_employee_roles,          -> { exists(employee_roles: true) }
  scope :all_employer_staff_roles,    -> { exists(employer_staff_roles: true) }
  scope :all_individual_market_transitions,  -> { exists(individual_market_transitions: true) }

  #scope :all_responsible_party_roles, -> { exists(responsible_party_role: true) }
  scope :all_broker_roles,            -> { exists(broker_role: true) }
  scope :all_hbx_staff_roles,         -> { exists(hbx_staff_role: true) }
  scope :all_csr_roles,               -> { exists(csr_role: true) }
  scope :all_assister_roles,          -> { exists(assister_role: true) }
  scope :all_broker_staff_roles,      -> { exists(broker_agency_staff_roles: true) }
  scope :all_agency_staff_roles,      lambda {
    where(
      {
        "$or" => [
            { "broker_agency_staff_roles" => { "$exists" => true } },
            { "general_agency_staff_roles" => { "$exists" => true }, "general_agency_staff_roles.is_primary" => {"$ne" => false} }
          ]
      }
    )
  }

  scope :by_hbx_id, ->(person_hbx_id) { where(hbx_id: person_hbx_id) }
  scope :by_broker_role_npn, ->(br_npn) { where("broker_role.npn" => br_npn) }
  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  #scope :broker_role_having_agency, -> { where("broker_role.broker_agency_profile_id" => { "$ne" => nil }) }
  scope :broker_role_having_agency, -> { where("broker_role.benefit_sponsors_broker_agency_profile_id" => { "$ne" => nil }) }
  scope :broker_role_applicant,     -> { where("broker_role.aasm_state" => { "$eq" => :applicant })}
  scope :broker_role_pending,       -> { where("broker_role.aasm_state" => { "$eq" => :broker_agency_pending })}
  scope :broker_role_certified,     -> { where("broker_role.aasm_state" => { "$in" => [:active]})}
  scope :broker_role_decertified,   -> { where("broker_role.aasm_state" => { "$eq" => :decertified })}
  scope :broker_role_extended,      -> { where("broker_role.aasm_state" => { "$eq" => :application_extended })}
  scope :broker_role_denied,        -> { where("broker_role.aasm_state" => { "$eq" => :denied })}
  scope :by_ssn,                    ->(ssn) { where(encrypted_ssn: Person.encrypt_ssn(ssn)) }
  scope :unverified_persons,        -> { where(:'consumer_role.aasm_state' => { "$ne" => "fully_verified" })}
  scope :matchable,                 ->(ssn, dob, last_name) { where(encrypted_ssn: Person.encrypt_ssn(ssn), dob: dob, last_name: last_name) }

  scope :general_agency_staff_applicant,     -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :applicant })}
  scope :general_agency_staff_certified,     -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :active })}
  scope :general_agency_staff_decertified,   -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :decertified })}
  scope :general_agency_staff_denied,        -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :denied })}
  # scope :general_agency_primary_staff,     -> { where("general_agency_staff_roles.is_primary" => { "$eq" => true })}

  scope :outstanding_identity_validation, -> { where(:'consumer_role.identity_validation' => { "$in" => [:pending] })}
  scope :outstanding_application_validation, -> { where(:'consumer_role.application_validation' => { "$in" => [:pending] })}
  scope :for_admin_approval, -> { any_of([outstanding_identity_validation.selector, outstanding_application_validation.selector]) }

#  ViewFunctions::Person.install_queries

  validate :consumer_fields_validations

  after_create :notify_created
  after_update :notify_updated

  def self.api_staff_roles
    Person.where(
      {
        "is_active" => true,
        "$or" => [
          { "broker_agency_staff_roles" => { "$exists" => true, "$not" => {"$size" => 0} } },
          { "general_agency_staff_roles.is_primary" =>  false }
        ]
      }
    )
  end

  def self.api_primary_staff_roles
    Person.where(
      {
        "is_active" => true,
        "$or" => [
          { "broker_role._id" => {"$exists" => true} },
          { "general_agency_staff_roles.is_primary" =>  true }
        ]
      }
    )
  end

  def agency_roles
    role_data(broker_agency_staff_roles, :benefit_sponsors_broker_agency_profile_id) + role_data(general_agency_staff_roles, :benefit_sponsors_general_agency_profile_id)
  end

  def role_data(data, agency)
    data.collect do |role|
      {
        aasm_state: role.aasm_state,
        agency_profile_id: role.try(agency).to_s,
        type: role.class.name,
        role_id: role._id.to_s,
        history: role.workflow_state_transitions
      }
    end
  end

  def agent_emails
    self.emails.collect do |email|
      {
        id: email.id.to_s,
        kind: email.kind,
        address: email.address
      }
    end
  end

  def has_active_enrollment
    if self.families.present?
      self.families.each do |family|
        household = family.active_household
        return true if household && household.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).present?
      end
    end
    false
  end

  def agent_npn
    self.general_agency_staff_roles.select(&:is_primary).try(:first).try(:npn) || self.broker_role.try(:npn)
  end

  def agent_role_id
    self.general_agency_staff_roles.select(&:is_primary).try(:first).try(:id) || self.broker_role.try(:id)
  end

  def connected_profile_id
    self.general_agency_staff_roles.select(&:is_primary).try(:first).try(:benefit_sponsors_general_agency_profile_id) || self.broker_role.try(:benefit_sponsors_broker_agency_profile_id)
  end

  def active_general_agency_staff_roles
    general_agency_staff_roles.where(:aasm_state => :active)
  end

  def has_active_general_agency_staff_role?
    !active_general_agency_staff_roles.empty?
  end

  def contact_addresses
    existing_addresses = addresses.to_a
    home_address = existing_addresses.detect { |addy| addy.kind == "home" }
    return existing_addresses if home_address
    add_employee_home_address(existing_addresses)
  end

  def add_employee_home_address(existing_addresses)
    return existing_addresses unless employee_roles.any?
    employee_contact_address = employee_roles.sort_by(&:hired_on).map(&:census_employee).compact.map(&:address).compact.first
    return existing_addresses unless employee_contact_address
    existing_addresses + [employee_contact_address]
  end

  def contact_phones
    phones.reject { |ph| ph.full_phone_number.blank? }
  end

  delegate :citizen_status, :citizen_status=, :to => :consumer_role, :allow_nil => true
  delegate :ivl_coverage_selected, :to => :consumer_role, :allow_nil => true
  delegate :all_types_verified?, :to => :consumer_role

  def notify_created
    # TODO: Possibly add
    # notify(PERSON_CREATED_EVENT_NAME, {:individual_id => self.hbx_id })
  end

  def notify_updated; end

  def is_aqhp?
    family = self.primary_family if self.primary_family
    if family
      check_households(family) && check_tax_households(family)
    else
      false
    end
  end

  def check_households(family)
    family.households.present? ? true : false
  end

  def check_tax_households(family)
    family.households.first.tax_households.present? ? true : false
  end

  def completed_identity_verification?
    return false unless user
    user.identity_verified?
  end

  def is_homeless?
    is_homeless
  end

  def is_temporarily_out_of_state?
    is_temporarily_out_of_state
  end

  #after_save :update_family_search_collection

  # before_save :notify_change
  # def notify_change
  #   notify_change_event(self, {"identifying_info"=>IDENTIFYING_INFO_ATTRIBUTES, "address_change"=>ADDRESS_CHANGE_ATTRIBUTES, "relation_change"=>RELATIONSHIP_CHANGE_ATTRIBUTES})
  # end

  def update_family_search_collection
    #  ViewFunctions::Person.run_after_save_search_update(self.id)
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_member_id) if hbx_id.blank?
  end

  def strip_empty_fields
    unset_sparse("encrypted_ssn") if encrypted_ssn.blank?

    unset_sparse("user_id") if user_id.blank?
  end

  def date_of_birth=(val)
    self.dob = begin
                 Date.strptime(val, "%m/%d/%Y").to_date
               rescue StandardError # rubocop:disable Lint/EmptyRescueClause
                 nil
               end
  end

  def gender=(new_gender)
    write_attribute(:gender, new_gender.to_s.downcase)
  end

  def financial_assistance_identifier
    primary_family&.id
  end

  # Get the {Family} where this {Person} is the primary family member
  #
  # family itegrity ensures only one active family can be the primary for a person
  #
  # @return [ Family ] the family member who matches this person
  def primary_family
    @primary_family ||= Family.find_primary_applicant_by_person(self).first
  end

  def families
    Family.find_all_by_person(self)
  end

  def full_name
    @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def first_name_last_name_and_suffix(seperator = nil)
    seperator = seperator.present? ? seperator : " "
    [first_name, last_name, name_sfx].compact.join(seperator)
    case name_sfx
    when "ii" || "iii" || "iv" || "v"
      [first_name.capitalize, last_name.capitalize, name_sfx.upcase].compact.join(seperator)
    else
      [first_name.capitalize, last_name.capitalize, name_sfx].compact.join(seperator)
      end
  end

  def is_active?
    is_active
  end

  def deactivate_types(types)
    types.each do |type|
      verification_type_by_name(type).update_attributes(:inactive => true) unless verification_type_by_name(type).inactive
    end
  end

  def add_new_verification_type(new_type)
    default_status = new_type == ConsumerRole::LOCATION_RESIDENCY && (consumer_role || resident_role) && age_on(TimeKeeper.date_of_record) < 18 ? "attested" : "unverified"
    if verification_types.map(&:type_name).include? new_type
      verification_type_by_name(new_type).update_attributes(:inactive => false)
    else
      verification_types << VerificationType.new(:type_name => new_type, :validation_status => default_status) unless us_citizen.nil?
    end
  end

  def verification_type_by_name(type)
    verification_types.find_by(:type_name => type)
  end

# collect all ridp_verification_types user in case of unsuccessful ridp
  def ridp_verification_types
    ridp_verification_types = []
    ridp_verification_types << 'Identity' if consumer_role && !consumer_role.person.completed_identity_verification?
    ridp_verification_types << 'Application' if consumer_role && !consumer_role.person.completed_identity_verification?
    ridp_verification_types
  end

  def relatives
    person_relationships.reject do |p_rel|
      p_rel.relative_id.to_s == self.id.to_s
    end.map(&:relative)
  end

  def find_relationship_with(other_person)
    if self.id == other_person.id
      "self"
    else
      person_relationship_for(other_person).try(:kind)
    end
  end

  def person_relationship_for(other_person)
    person_relationships.detect do |person_relationship|
      person_relationship.relative_id == other_person.id
    end
  end

  def ensure_relationship_with(person, relationship)
    return if person.blank?
    existing_relationship = self.person_relationships.detect do |rel|
      rel.relative_id.to_s == person.id.to_s
    end
    if existing_relationship
      existing_relationship.update_attributes(:kind => relationship)
    elsif id != person.id
      self.person_relationships << PersonRelationship.new({
                                                            :kind => relationship,
                                                            :relative_id => person.id
                                                          })
    end
  end

  def add_work_email(email)
    existing_email = self.emails.detect do |e|
      (e.kind == 'work') &&
        (e.address.downcase == email.downcase)
    end
    return nil if existing_email.present?
    self.emails << ::Email.new(:kind => 'work', :address => email)
  end

  def home_address
    addresses.detect { |adr| adr.kind == "home" }
  end

  def mailing_address
    addresses.detect { |adr| adr.kind == "mailing" } || home_address
  end

  def has_mailing_address?
    addresses.any? { |adr| adr.kind == "mailing" }
  end

  def home_email
    emails.detect { |adr| adr.kind == "home" }
  end

  def work_email
    emails.detect { |adr| adr.kind == "work" }
  end

  def work_email_or_best
    email = emails.detect { |adr| adr.kind == "work" } || emails.first
    email&.address || user&.email
  end

  def work_phone
    phones.detect { |phone| phone.kind == "work" } || main_phone
  end

  def main_phone
    phones.detect { |phone| phone.kind == "main" }
  end

  def home_phone
    phones.detect { |phone| phone.kind == "home" }
  end

  def mobile_phone
    phones.detect { |phone| phone.kind == "mobile" }
  end

  def work_phone_or_best
    best_phone = work_phone || mobile_phone || home_phone
    best_phone ? best_phone.full_phone_number : nil
  end

  def has_active_consumer_role?
    consumer_role.present? && consumer_role.is_active?
  end

  def has_active_resident_role?
    resident_role.present? && resident_role.is_active?
  end

  def has_active_resident_member?
    if self.primary_family.present?
      active_resident_member = self.primary_family.active_family_members.detect { |member| member.person.is_resident_role_active? }
      return true if active_resident_member.present?
    end
    false
  end

  def has_active_consumer_member?
    if self.primary_family.present?
      active_consumer_member = self.primary_family.active_family_members.detect { |member| member.person.is_consumer_role_active? }
      return true if active_consumer_member.present?
    end
    false
  end

  def can_report_shop_qle?
    employee_roles.first.census_employee.qle_30_day_eligible?
  end

  def has_active_employee_role?
    active_employee_roles.any?
  end

  def has_employer_benefits?
    active_employee_roles.present? #&& active_employee_roles.any?{|r| r.benefit_group.present?}
  end

  def active_employee_roles
    employee_roles.select{|employee_role| employee_role.census_employee&.is_active? }
  end

  def has_multiple_active_employers?
    active_employee_roles.count > 1
  end

  def has_active_employer_staff_role?
    employer_staff_roles.present? && employer_staff_roles.active.present?
  end

  def active_employer_staff_roles
    employer_staff_roles.present? ? employer_staff_roles.active : []
  end

  def has_multiple_roles?
    consumer_role.present? && active_employee_roles.present?
  end

  def has_active_employee_role_for_census_employee?(census_employee)
    (active_employee_roles.detect { |employee_role| employee_role.census_employee == census_employee }).present? if census_employee
  end

  def residency_eligible?
    is_homeless? || is_temporarily_out_of_state?
  end

  def age_on(date)
    age = date.year - dob.year
    if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
      age - 1
    else
      age
    end
  end

  def is_homeless?
    is_homeless
  end

  def is_temporarily_out_of_state?
    is_temporarily_out_of_state
  end

  def is_dc_resident?
    return true if is_homeless? || is_temporarily_out_of_state?

    address_to_use = addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
    addresses.each{|address| return true if address.kind == address_to_use && address.state == aca_state_abbreviation}
    false
  end

  def current_individual_market_transition
    self.individual_market_transitions.last if self.individual_market_transitions.present?
  end

  def active_individual_market_role
    current_individual_market_transition.role_type if current_individual_market_transition.present? && current_individual_market_transition.role_type
  end

  def has_consumer_or_resident_role?
    is_consumer_role_active? || is_resident_role_active?
  end

  def is_consumer_role_active?
    self.active_individual_market_role == "consumer"
  end

  def is_resident_role_active?
    self.active_individual_market_role == "resident"
  end

  def has_pending_broker_staff_role?(broker_agency_profile_id)
    !broker_agency_staff_roles.where({
                                       aasm_state: :broker_agency_pending,
                                       '$or' => [
                                        {benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id},
                                        {broker_agency_profile_id: broker_agency_profile_id}
                                      ]
                                     }).empty?
  end

  def has_pending_ga_staff_role?(general_agency_profile_id)
    !general_agency_staff_roles.where({
                                        aasm_state: :general_agency_pending,
                                        '$or' => [
                                        {benefit_sponsors_general_agency_profile_id: general_agency_profile_id},
                                        {general_agency_profile_id: general_agency_profile_id}
                                      ]
                                      }).empty?
  end

  def active_broker_staff_roles
    broker_agency_staff_roles.where(:aasm_state => :active)
  end

  def has_active_broker_staff_role?
    !active_broker_staff_roles.empty?
  end

  def general_agency_primary_staff
    general_agency_staff_roles.present? ? general_agency_staff_roles.where(is_primary: true).first : nil
  end

  class << self

    def default_search_order
      [[:last_name, 1],[:first_name, 1]]
    end

    def search_hash(s_str)
      clean_str = s_str.strip
      s_rex = Regexp.new("^" + Regexp.escape(clean_str), true)
      if clean_str =~ /[a-z]/i
        {
          "$or" => ([
            {"first_name" => s_rex},
            {"last_name" => s_rex}
          ] + additional_exprs(clean_str))
        }
      else
        {
          "$or" => [
            {"hbx_id" => s_rex},
            {"encrypted_ssn" => encrypt_ssn(clean_str)}
          ]
        }
      end
    end

    def broker_ga_search_hash(s_str)
      clean_str = s_str.strip
      s_rex = Regexp.new("^" + Regexp.escape(clean_str), true)
      if clean_str =~ /[a-z]/i
        {
          "$or" => ([
            {"first_name" => s_rex},
            {"last_name" => s_rex}
          ] + additional_exprs(clean_str))
        }
      else
        {
          "$or" => [
            {"broker_role.npn" => s_rex},
            {"general_agency_staff_roles.npn" => s_rex}
          ]
        }
      end
    end

    def additional_exprs(clean_str)
      additional_exprs = []
      if clean_str.include?(" ")
        parts = clean_str.split(" ").compact
        first_re = ::Regexp.new(::Regexp.escape(parts.first), true)
        last_re = ::Regexp.new(::Regexp.escape(parts.last), true)
        additional_exprs << {:first_name => first_re, :last_name => last_re}
      end
      additional_exprs
    end

    def search_first_name_last_name_npn(s_str, query = self)
      clean_str = s_str.strip
      if clean_str =~ /[a-z]/i
        people_user_ids = query.collection.aggregate([
                            {"$match" => {
                              "$text" => {"$search" => clean_str}
                            }.merge(Person.broker_ga_search_hash(clean_str))},
                            {"$project" => {"first_name" => 1, "last_name" => 1, "full_name" => 1}},
                            {"$sort" => {"last_name" => 1, "first_name" => 1}},
                            {"$project" => {"_id" => 1}}
                          ], {allowDiskUse: true}).map do |rec|
                            rec["_id"]
                          end
        query.where(:id => {"$in" => people_user_ids})
      else
        query.where(broker_ga_search_hash(s_str))
      end
    end

    def brokers_matching_search_criteria(search_str)
      broker_role_certified.search_first_name_last_name_npn(search_str)
    end

    def agencies_with_matching_broker(search_str)
      if brokers_matching_search_criteria(search_str).exists(:"broker_role.benefit_sponsors_broker_agency_profile_id" => true)
        brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:benefit_sponsors_broker_agency_profile_id)
      else
        brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:broker_agency_profile_id)
      end
    end

    def general_agencies_matching_search_criteria(search_str)
      general_agency_staff_certified.search_first_name_last_name_npn(search_str)
    end

    # Find all employee_roles.  Since person has_many employee_roles, person may show up
    # employee_role.person may not be unique in returned set
    def employee_roles
      people = exists(:'employee_roles.0' => true).entries
      people.flat_map(&:employee_roles)
    end

    def find_all_brokers_or_staff_members_by_agency(broker_agency)
      Person.or({:"broker_role.broker_agency_profile_id" => broker_agency.id},
                {:"broker_agency_staff_roles.broker_agency_profile_id" => broker_agency.id})
    end

    def sans_primary_broker(broker_agency)
      where(:"broker_role._id".nin => [broker_agency.primary_broker_role_id])
    end

    def find_all_staff_roles_by_employer_profile(employer_profile)
      #where({"$and"=>[{"employer_staff_roles.employer_profile_id"=> employer_profile.id}, {"employer_staff_roles.is_owner"=>true}]})
      staff_for_employer(employer_profile)
    end

    def match_existing_person(personish)
      return nil if personish.ssn.blank?
      Person.where(:encrypted_ssn => encrypt_ssn(personish.ssn), :dob => personish.dob).first
    end

    def person_has_an_active_enrollment?(person)
      if !person.primary_family.blank? && !person.primary_family.enrollments.blank?
        person.primary_family.enrollments.each do |enrollment|
          return true if enrollment.is_active
        end
      end
      false
    end

    def dob_change_implication_on_active_enrollments(person, new_dob)
      # This method checks if there is a premium implication in all active enrollments when a persons DOB is changed.
      # Returns a hash with Key => HbxEnrollment ID and, Value => true if  enrollment has Premium Implication.
      premium_impication_for_enrollment = {}
      active_enrolled_hbxs = person.primary_family.active_household.hbx_enrollments.active.enrolled_and_renewal

      # Iterate over each enrollment and check if there is a Premium Implication based on the following rule:
      # Rule: There are Implications when DOB changes makes anyone in the household a different age on the day coverage started UNLESS the
      #       change is all within the 0-20 age range or all within the 61+ age range (20 >= age <= 61)
      active_enrolled_hbxs.each do |hbx|
        new_temp_person = person.dup
        new_temp_person.dob = Date.strptime(new_dob.to_s, '%m/%d/%Y')
        new_age = new_temp_person.age_on(hbx.effective_on)  # age with the new DOB on the day coverage started
        current_age = person.age_on(hbx.effective_on)           # age with the current DOB on the day coverage started

        next if new_age == current_age # No Change in age -> No Premium Implication

        # No Implication when the change is all within the 0-20 age range or all within the 61+ age range
        if (current_age.between?(0,20) && new_age.between?(0,20)) || (current_age >= 61 && new_age >= 61)
          #premium_impication_for_enrollment[hbx.id] = false
        else
          premium_impication_for_enrollment[hbx.id] = true
        end
      end
      premium_impication_for_enrollment
    end

    # Return an instance list of active People who match identifying information criteria
    def match_by_id_info(options)
      ssn_query = options[:ssn]
      dob_query = options[:dob]
      last_name = options[:last_name]
      first_name = options[:first_name]

      raise ArgumentError, "must provide an ssn or first_name/last_name/dob or both" if ssn_query.blank? && (dob_query.blank? || last_name.blank? || first_name.blank?)

      matches = []
      matches.concat Person.active.where(encrypted_ssn: encrypt_ssn(ssn_query), dob: dob_query).to_a unless ssn_query.blank?
      #matches.concat Person.where(last_name: last_name, dob: dob_query).active.to_a unless (dob_query.blank? || last_name.blank?)
      if first_name.present? && last_name.present? && dob_query.present?
        first_exp = /^#{first_name}$/i
        last_exp = /^#{last_name}$/i
        matches.concat Person.active.where(dob: dob_query, last_name: last_exp, first_name: first_exp).to_a.select{|person| person.ssn.blank? || ssn_query.blank?}
      end
      matches.uniq
    end

    def brokers_or_agency_staff_with_status(query, status)
      query.and(
        Person.or(
          { :"broker_agency_staff_roles.aasm_state" => status },
          { :"broker_role.aasm_state" => status }
        ).selector
      )
    end

    def staff_for_employer(employer_profile)
      if employer_profile.is_a? EmployerProfile
        self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                       employer_profile_id: employer_profile.id,
                       aasm_state: :is_active
                     }
                   }).to_a
      else
        self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                       benefit_sponsor_employer_profile_id: employer_profile.id,
                       aasm_state: :is_active
                     }
                   }).to_a
      end
    end

    def staff_for_broker(broker_profile)
      Person.where(:broker_agency_staff_roles =>
                     {
                       '$elemMatch' =>
                         {
                           aasm_state: :active,
                           '$or' => [
                             {benefit_sponsors_broker_agency_profile_id: broker_profile.id},
                             {broker_agency_profile_id: broker_profile.id}
                           ]
                         }
                     })
    end

    def staff_for_ga(general_agency_profile)
      Person.where(:general_agency_staff_roles =>
                     {
                       '$elemMatch' =>
                         {
                           aasm_state: :active,
                           '$or' => [
                             {benefit_sponsors_general_agency_profile_id: general_agency_profile.id},
                             {general_agency_profile_id: general_agency_profile.id}
                           ]
                         }
                     })
    end

    def staff_for_employer_including_pending(employer_profile)
      if employer_profile.is_a? EmployerProfile
        self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                       employer_profile_id: employer_profile.id,
                       :aasm_state.ne => :is_closed
                     }
                   })
      else
        self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                       benefit_sponsor_employer_profile_id: employer_profile.id,
                       :aasm_state.ne => :is_closed
                     }
                   })
      end
    end

    def staff_for_broker_including_pending(broker_profile)
      Person.where(:broker_agency_staff_roles =>
                     {
                       '$elemMatch' => {
                         '$and' => [
                           {
                             '$or' => [
                               {benefit_sponsors_broker_agency_profile_id: broker_profile.id}
                             ]
                           },
                           {
                             '$or' => [
                               {aasm_state: :broker_agency_pending},
                               {aasm_state: :active}
                             ]
                           }
                         ]
                       }
                     })
    end

    def staff_for_ga_including_pending(general_agency_profile)
      Person.where(:general_agency_staff_roles =>
                     {
                       '$elemMatch' => {
                         '$and' => [
                           {
                             '$or' => [
                               {benefit_sponsors_general_agency_profile_id: general_agency_profile.id}
                             ]
                           },
                           {
                             '$or' => [
                               {aasm_state: :general_agency_pending},
                               {aasm_state: :active}
                             ]
                           }
                         ]
                       }
                     })
    end

    # Adds employer staff role to person
    # Returns status and message if failed
    # Returns status and person if successful
    def add_employer_staff_role(first_name, last_name, dob, _email, employer_profile)
      person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

      return false, 'Person count too high, please contact HBX Admin' if person.count > 1
      return false, 'Person does not exist on the HBX Exchange' if person.count == 0

      employer_staff_role = if employer_profile.is_a? EmployerProfile
                              EmployerStaffRole.create(person: person.first, employer_profile_id: employer_profile._id)
                            else
                              EmployerStaffRole.create(person: person.first, benefit_sponsor_employer_profile_id: employer_profile._id)
                            end

      employer_staff_role.save

      [true, person.first]
    end

    # Sets employer staff role to inactive
    # Returns false if person not found
    # Returns false if employer staff role not matches
    # Returns true is role was marked inactive
    def deactivate_employer_staff_role(person_id, employer_profile_id)
      begin
        person = Person.find(person_id)
      rescue StandardError
        return false, 'Person not found'
      end
      if role = person.employer_staff_roles.detect{|role| (role.benefit_sponsor_employer_profile_id.to_s == employer_profile_id.to_s || role.employer_profile_id.to_s == employer_profile_id.to_s) && !role.is_closed?}
        role.update_attributes!(:aasm_state => :is_closed)
        [true, 'Employee Staff Role is inactive']
      else
        [false, 'No matching employer staff role']
      end
    end

  end

  # HACK
  # FIXME
  # TODO: Move this out of here
  attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status

  attr_accessor :is_consumer_role
  attr_accessor :is_resident_role

  before_save :assign_citizen_status_from_consumer_role

  def assign_citizen_status_from_consumer_role
    assign_citizen_status if is_consumer_role.to_s == "true"
  end

  def us_citizen=(val)
    @us_citizen = (val.to_s == "true")
    @naturalized_citizen = false if val.to_s == "false"
  end

  def naturalized_citizen=(val)
    @naturalized_citizen = (val.to_s == "true")
  end

  def indian_tribe_member=(val)
    self.tribal_id = nil if val.to_s == false
    @indian_tribe_member = (val.to_s == "true")
  end

  def eligible_immigration_status=(val)
    @eligible_immigration_status = (val.to_s == "true")
  end

  def us_citizen
    return @us_citizen unless @us_citizen.nil?
    return nil if citizen_status.blank?
    @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(citizen_status)
  end

  def naturalized_citizen
    return @naturalized_citizen unless @naturalized_citizen.nil?
    return nil if citizen_status.blank?
    @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == citizen_status)
  end

  def indian_tribe_member
    return @indian_tribe_member unless @indian_tribe_member.nil?
    return nil if citizen_status.blank?
    @indian_tribe_member ||= !(tribal_id.nil? || tribal_id.empty?)
  end

  def eligible_immigration_status
    return @eligible_immigration_status unless @eligible_immigration_status.nil?
    return nil if us_citizen.nil?
    return nil if @us_citizen
    return nil if citizen_status.blank?
    @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == citizen_status)
  end

  def assign_citizen_status
    new_status = nil
    if naturalized_citizen
      new_status = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS
    elsif us_citizen
      new_status = ::ConsumerRole::US_CITIZEN_STATUS
    elsif eligible_immigration_status
      new_status = ::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS
    elsif !eligible_immigration_status.nil?
      new_status = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
    elsif
      self.errors.add(:base, "Citizenship status can't be nil.")
    end
    self.consumer_role.lawful_presence_determination.assign_citizen_status(new_status) if new_status
  end

  def agent?
    agent = csr_role || assister_role || broker_role || hbx_staff_role || general_agency_staff_roles.present? || broker_agency_staff_roles.present?
    !!agent
  end

  def contact_info(email_address, area_code, number, extension)
    if email_address.present?
      email = emails.detect{|mail| mail.kind == 'work'}
      if email
        email.update_attributes!(address: email_address)
      else
        emails.build(kind: 'work', address: email_address)
        save
      end
    end
    phone = phones.detect{|p| p.kind == 'work'}
    if phone
      phone.update_attributes!(area_code: area_code, number: number, extension: extension)
    else
      phones.build(kind: 'work', area_code: area_code, number: number, extension: extension)
      save
    end
  end

  def generate_family_search
    ::MapReduce::FamilySearchForPerson.populate_for(self)
  end

  def set_ridp_for_paper_application(session_var)
    if user && session_var == 'paper'
      user.ridp_by_paper_application
      consumer_role&.move_identity_documents_to_verified
    end
  end

  # Related to Relationship Matrix
  def add_relationship(successor, relationship_kind, family_id, destroy_relation = false)
    if same_successor_exists?(successor, family_id)
      direct_relationship = person_relationships.where(family_id: family_id, predecessor_id: self.id, successor_id: successor.id).first # Direct Relationship

      # Destroying the relationships associated to the Person other than the new updated relationship.
      if !direct_relationship.nil? && destroy_relation
        other_relations = person_relationships.where(family_id: family_id, predecessor_id: self.id, :id.nin => [direct_relationship.id]).map(&:successor_id)
        person_relationships.where(family_id: family_id, predecessor_id: self.id, :id.nin => [direct_relationship.id]).each(&:destroy)

        other_relations.each do |otr|
          otr_relation = Person.find(otr).person_relationships.where(family_id: family_id, predecessor_id: otr, successor_id: self.id).first
          otr_relation.destroy unless otr_relation.blank?
        end
      end

      direct_relationship.update(kind: relationship_kind)
    elsif self.id != successor.id
      person_relationships.create(family_id: family_id, predecessor_id: self.id, successor_id: successor.id, kind: relationship_kind, relative_id: self.id) # Direct Relationship
    end
  end

  def same_successor_exists?(successor, family_id)
    person_relationships.where(family_id: family_id, predecessor_id: self.id, successor_id: successor.id).first.present?
  end

  def build_relationship(successor, relationship_kind, family_id)
    person_relationships.build(family_id: family_id, predecessor_id: self.id, successor_id: successor.id, kind: relationship_kind) # Direct Relationship
  end

  def remove_relationship(family_id)
    successor_ids = person_relationships.where(family_id: family_id, predecessor_id: self.id).collect(&:successor_id)
    person_relationships.where(family_id: family_id, predecessor_id: self.id).each(&:destroy)
    successor_ids.each do |s|
      Person.find(s).person_relationships.where(family_id: family_id, successor_id: self.id).each(&:destroy)
    end
  end

  private

  def is_ssn_composition_correct?
    # Invalid compositions:
    #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
    #   00 in the group number (fourth and fifth digit); or
    #   0000 in the serial number (last four digits)

    if ssn.present?
      invalid_area_numbers = %w[000 666]
      invalid_area_range = 900..999
      invalid_group_numbers = %w[00]
      invalid_serial_numbers = %w[0000]

      return false if ssn.to_s.blank?
      return false if invalid_area_numbers.include?(ssn.to_s[0,3])
      return false if invalid_area_range.include?(ssn.to_s[0,3].to_i)
      return false if invalid_group_numbers.include?(ssn.to_s[3,2])
      return false if invalid_serial_numbers.include?(ssn.to_s[5,4])
    end

    true
  end

  def is_only_one_individual_role_active?
    self.errors.add(:base, "Resident role and Consumer role can't both be active at the same time.") if self.is_consumer_role_active? && self.is_resident_role_active?
    true
  end

  def create_inbox
    welcome_subject = "Welcome to #{site_short_name}"
    welcome_body = if broker_role || broker_agency_staff_roles.present?
                     "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
                   else
                     "#{site_short_name} is ready to help you get quality, affordable medical or dental coverage that meets your needs and budget.<br/><br/>Now that you’ve created an account, take a moment to explore your account features. Remember there’s limited time to sign up for a plan. Make sure you pay attention to deadlines.<br/><br/>If you have any questions or concerns, we’re here to help.<br/><br/>#{site_short_name}<br/>#{contact_center_short_number}<br/>TTY: #{contact_center_tty_number}"
                   end
    mailbox = Inbox.create(recipient: self)
    mailbox.messages.create(subject: welcome_subject, body: welcome_body, from: site_short_name.to_s)
  end

  def update_full_name
    full_name
  end

  def no_changing_my_user
    if self.persisted? && self.user_id_changed?
      old_user, new_user = self.user_id_change
      return if old_user.blank?
      errors.add(:base, "you may not change the user_id of a person once it has been set and saved") if old_user != new_user
    end
  end

  # Verify basic date rules
  def date_functional_validations
    date_of_death_is_blank_or_past
    date_of_death_follows_date_of_birth
  end

  def date_of_death_is_blank_or_past
    return unless self.date_of_death.present?
    errors.add(:date_of_death, "future date: #{self.date_of_death} is invalid date of death") if TimeKeeper.date_of_record < self.date_of_death
  end

  def date_of_death_follows_date_of_birth
    return unless self.date_of_death.present? && self.dob.present?

    if self.date_of_death < self.dob
      errors.add(:date_of_death, "date of death cannot preceed date of birth")
      errors.add(:dob, "date of birth cannot follow date of death")
    end
  end

  def consumer_fields_validations
    return unless @is_consumer_role.to_s == 'true' && consumer_role.is_applying_coverage.to_s == 'true' #only check this for consumer flow.

    citizenship_validation
    native_american_validation
    incarceration_validation
  end

  def native_american_validation
    self.errors.add(:base, "American Indian / Alaska Native status is required.") if indian_tribe_member.to_s.blank?
    if !tribal_id.present? && @us_citizen == true && @indian_tribe_member == true
      self.errors.add(:base, "Tribal id is required when native american / alaska native is selected")
    elsif tribal_id.present? && !tribal_id.match("[0-9]{9}")
      self.errors.add(:base, "Tribal id must be 9 digits")
    end
  end

  def citizenship_validation
    if @us_citizen.to_s.blank?
      self.errors.add(:base, "Citizenship status is required.")
    elsif @us_citizen == false && @eligible_immigration_status.nil?
      self.errors.add(:base, "Eligible immigration status is required.")
    elsif @us_citizen == true && @naturalized_citizen.nil?
      self.errors.add(:base, "Naturalized citizen is required.")
    end
  end

  def incarceration_validation
    self.errors.add(:base, "Incarceration status is required.") if is_incarcerated.to_s.blank?
  end
end

# rubocop:enable all
