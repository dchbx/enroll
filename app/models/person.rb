class Person
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include Mongoid::Versioning

  include Notify
  include UnsetableSparseFields
  include FullStrippedNames

  extend Mongorder
#  validates_with Validations::DateRangeValidator


  GENDER_KINDS = %W(male female)
  IDENTIFYING_INFO_ATTRIBUTES = %w(first_name last_name ssn dob)
  ADDRESS_CHANGE_ATTRIBUTES = %w(addresses phones emails)
  RELATIONSHIP_CHANGE_ATTRIBUTES = %w(person_relationships)

  PERSON_CREATED_EVENT_NAME = "acapi.info.events.individual.created"
  PERSON_UPDATED_EVENT_NAME = "acapi.info.events.individual.updated"

  field :hbx_id, type: String
  field :name_pfx, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String
  field :full_name, type: String
  field :alternate_name, type: String

  # Sub-model in-common attributes
  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :gender, type: String
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
  field :no_dc_address_reason, type: String, default: ""

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :no_ssn, type: String #ConsumerRole TODO TODOJF
  # Login account
  belongs_to :user

  belongs_to :employer_contact,
                class_name: "EmployerProfile",
                inverse_of: :employer_contacts,
                index: true

  belongs_to :broker_agency_contact,
                class_name: "BrokerAgencyProfile",
                inverse_of: :broker_agency_contacts,
                index: true

  belongs_to :general_agency_contact,
                class_name: "GeneralAgencyProfile",
                inverse_of: :general_agency_contacts,
                index: true

  embeds_one :consumer_role, cascade_callbacks: true, validate: true
  embeds_one :broker_role, cascade_callbacks: true, validate: true
  embeds_one :hbx_staff_role, cascade_callbacks: true, validate: true
  embeds_one :responsible_party, cascade_callbacks: true, validate: true
  embeds_one :csr_role, cascade_callbacks: true, validate: true
  embeds_one :assister_role, cascade_callbacks: true, validate: true
  embeds_one :inbox, as: :recipient

  embeds_many :employer_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :employee_roles, cascade_callbacks: true, validate: true
  embeds_many :general_agency_staff_roles, cascade_callbacks: true, validate: true

  embeds_many :person_relationships, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true
  embeds_many :documents, as: :documentable

  accepts_nested_attributes_for :consumer_role, :responsible_party, :broker_role, :hbx_staff_role,
    :person_relationships, :employee_roles, :phones, :employer_staff_roles

  accepts_nested_attributes_for :phones, :reject_if => Proc.new { |addy| Phone.new(addy).blank? }
  accepts_nested_attributes_for :addresses, :reject_if => Proc.new { |addy| Address.new(addy).blank? }
  accepts_nested_attributes_for :emails, :reject_if => Proc.new { |addy| Email.new(addy).blank? }

  validates_presence_of :first_name, :last_name
  validate :date_functional_validations
  validate :no_changing_my_user, :on => :update

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
    allow_blank: true

  validates :encrypted_ssn, uniqueness: true, allow_blank: true

  validate :is_ssn_composition_correct?

  validates :gender,
    allow_blank: true,
    inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }

  before_save :generate_hbx_id
  before_save :update_full_name
  before_save :strip_empty_fields
  #after_save :generate_family_search
  after_create :create_inbox

  index({hbx_id: 1}, {sparse:true, unique: true})
  index({user_id: 1}, {sparse:true, unique: true})

  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name: 1})

  index({encrypted_ssn: 1}, {sparse: true, unique: true})
  index({dob: 1}, {sparse: true})
  index({dob: 1, encrypted_ssn: 1})

  index({last_name: 1, dob: 1}, {sparse: true})

  # Broker child model indexes
  index({"broker_role._id" => 1})
  index({"broker_role.provider_kind" => 1})
  index({"broker_role.broker_agency_id" => 1})
  index({"broker_role.npn" => 1}, {sparse: true, unique: true})

  # Employer role index
  index({"employer_staff_role._id" => 1})
  index({"employer_staff_role.employer_profile_id" => 1})

  # Consumer child model indexes
  index({"consumer_role._id" => 1})
  index({"consumer_role.aasm_state" => 1})
  index({"consumer_role.is_active" => 1})

  # Employee child model indexes
  index({"employee_roles._id" => 1})
  index({"employee_roles.employer_profile_id" => 1})
  index({"employee_roles.benefit_group_id" => 1})
  index({"employee_roles.is_active" => 1})

  # HbxStaff child model indexes
  index({"hbx_staff_role._id" => 1})
  index({"hbx_staff_role.is_active" => 1})

  # PersonRelationship child model indexes
  index({"person_relationship.relative_id" =>  1})

  index({"hbx_employer_staff_role._id" => 1})
  index({"hbx_responsible_party_role._id" => 1})
  index({"hbx_csr_role._id" => 1})
  index({"hbx_assister._id" => 1})

  scope :all_consumer_roles,          -> { exists(consumer_role: true) }
  scope :all_employee_roles,          -> { exists(employee_roles: true) }
  scope :all_employer_staff_roles,    -> { exists(employer_staff_role: true) }
  scope :all_responsible_party_roles, -> { exists(responsible_party_role: true) }
  scope :all_broker_roles,            -> { exists(broker_role: true) }
  scope :all_hbx_staff_roles,         -> { exists(hbx_staff_role: true) }
  scope :all_csr_roles,               -> { exists(csr_role: true) }
  scope :all_assister_roles,          -> { exists(assister_role: true) }

  scope :by_hbx_id, ->(person_hbx_id) { where(hbx_id: person_hbx_id) }
  scope :by_broker_role_npn, ->(br_npn) { where("broker_role.npn" => br_npn) }
  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  scope :broker_role_having_agency, -> { where("broker_role.broker_agency_profile_id" => { "$ne" => nil }) }
  scope :broker_role_applicant,     -> { where("broker_role.aasm_state" => { "$eq" => :applicant })}
  scope :broker_role_pending,       -> { where("broker_role.aasm_state" => { "$eq" => :broker_agency_pending })}
  scope :broker_role_certified,     -> { where("broker_role.aasm_state" => { "$in" => [:active, :broker_agency_pending]})}
  scope :broker_role_decertified,   -> { where("broker_role.aasm_state" => { "$eq" => :decertified })}
  scope :broker_role_denied,        -> { where("broker_role.aasm_state" => { "$eq" => :denied })}
  scope :by_ssn,                    ->(ssn) { where(encrypted_ssn: Person.encrypt_ssn(ssn)) }
  scope :unverified_persons,        -> { where(:'consumer_role.aasm_state' => { "$ne" => "fully_verified" })}
  scope :matchable,                 ->(ssn, dob, last_name) { where(encrypted_ssn: Person.encrypt_ssn(ssn), dob: dob, last_name: last_name) }

  scope :general_agency_staff_applicant,     -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :applicant })}
  scope :general_agency_staff_certified,     -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :active })}
  scope :general_agency_staff_decertified,   -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :decertified })}
  scope :general_agency_staff_denied,        -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :denied })}

#  ViewFunctions::Person.install_queries

  validate :consumer_fields_validations

  after_create :notify_created
  after_update :notify_updated

  delegate :citizen_status, :citizen_status=, :to => :consumer_role, :allow_nil => true
  delegate :ivl_coverage_selected, :to => :consumer_role, :allow_nil => true
  delegate :all_types_verified?, :to => :consumer_role


  def notify_created
    notify(PERSON_CREATED_EVENT_NAME, {:individual_id => self.hbx_id } )
  end

  def notify_updated
    notify(PERSON_UPDATED_EVENT_NAME, {:individual_id => self.hbx_id } ) if need_to_notify?
  end

  def need_to_notify?
    changed_fields = changed_attributes.keys
    changed_fields << consumer_role.changed_attributes.keys if consumer_role.present?
    changed_fields << employee_roles.map(&:changed_attributes).map(&:keys) if employee_roles.present?
    changed_fields << employer_staff_roles.map(&:changed_attributes).map(&:keys) if employer_staff_roles.present?
    changed_fields = changed_fields.flatten.compact.uniq
    notify_fields = changed_fields.reject{|field| ["bookmark_url", "updated_at"].include?(field)}
    notify_fields.present?
  end

  def is_aqhp?
    family = self.primary_family if self.primary_family
    if family
      check_households(family) && check_tax_households(family)
    else
      false
    end
  end

  def check_households family
    family.households.present? ? true : false
  end

  def check_tax_households family
    family.households.first.tax_households.present? ? true : false
  end

  def completed_identity_verification?
    return false unless user
    user.identity_verified?
  end

  def consumer_fields_validations
    if self.is_consumer_role.to_s == "true"
      if !tribal_id.present? && @us_citizen == true && @indian_tribe_member == true
        self.errors.add(:base, "Tribal id is required when native american / alaskan native is selected")
      elsif tribal_id.present? && !tribal_id.match("[0-9]{9}")
        self.errors.add(:base, "Tribal id must be 9 digits")
      end
    end
  end

  #after_save :update_family_search_collection
  after_validation :move_encrypted_ssn_errors

  def move_encrypted_ssn_errors
    deleted_messages = errors.delete(:encrypted_ssn)
    if !deleted_messages.blank?
      deleted_messages.each do |dm|
        errors.add(:ssn, dm)
      end
    end
    true
  end

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
    if encrypted_ssn.blank?
      unset_sparse("encrypted_ssn")
    end
    if user_id.blank?
      unset_sparse("user_id")
    end
  end
  def ssn_changed?
    encrypted_ssn_changed?
  end

  def self.encrypt_ssn(val)
    if val.blank?
      return nil
    end
    ssn_val = val.to_s.gsub(/\D/, '')
    SymmetricEncryption.encrypt(ssn_val)
  end

  def self.decrypt_ssn(val)
    SymmetricEncryption.decrypt(val)
  end

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(new_ssn)
    if !new_ssn.blank?
      write_attribute(:encrypted_ssn, Person.encrypt_ssn(new_ssn))
    else
      unset_sparse("encrypted_ssn")
    end
  end

  def ssn
    ssn_val = read_attribute(:encrypted_ssn)
    if !ssn_val.blank?
      Person.decrypt_ssn(ssn_val)
    else
      nil
    end
  end

  def gender=(new_gender)
    write_attribute(:gender, new_gender.to_s.downcase)
  end

  def date_of_birth
    self.dob.blank? ? nil : self.dob.strftime("%m/%d/%Y")
  end

  def date_of_birth=(val)
    self.dob = Date.strptime(val, "%m/%d/%Y").to_date rescue nil
  end

  def primary_family
    @primary_family ||= Family.find_by_primary_applicant(self)
  end

  def families
    Family.find_all_by_person(self)
  end

  def full_name
    @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def first_name_last_name_and_suffix
    [first_name, last_name, name_sfx].compact.join(" ")
    case name_sfx
      when "ii" ||"iii" || "iv" || "v"
        [first_name.capitalize, last_name.capitalize, name_sfx.upcase].compact.join(" ")
      else
        [first_name.capitalize, last_name.capitalize, name_sfx].compact.join(" ")
      end
  end

  def age_on(date)
    age = date.year - dob.year
    if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
      age - 1
    else
      age
    end
  end

  def dob_to_string
    dob.blank? ? "" : dob.strftime("%Y%m%d")
  end

  def is_active?
    is_active
  end

  # collect all verification types user can have based on information he provided
  def verification_types
    verification_types = []
    verification_types << 'Social Security Number' if ssn
    verification_types << 'American Indian Status' if citizen_status && ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS.include?(citizen_status)
    if self.us_citizen
      verification_types << 'Citizenship'
    else
      verification_types << 'Immigration status'
    end
    verification_types
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
    existing_relationship = self.person_relationships.detect do |rel|
      rel.relative_id.to_s == person.id.to_s
    end
    if existing_relationship
      existing_relationship.update_attributes(:kind => relationship)
    else
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
    (email && email.address) || (user && user.email)
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
    best_phone  = work_phone || mobile_phone || home_phone
    best_phone ? best_phone.full_phone_number : nil
  end

  def has_active_consumer_role?
    consumer_role.present? and consumer_role.is_active?
  end

  def can_report_shop_qle?
    employee_roles.first.census_employee.qle_30_day_eligible?
  end

  def has_active_employee_role?
    active_employee_roles.any?
  end

  def has_employer_benefits?
    active_employee_roles.present? && active_employee_roles.first.benefit_group.present?
  end

  def active_employee_roles
    employee_roles.select{|employee_role| employee_role.census_employee && employee_role.census_employee.is_active? }
  end

  def has_active_employer_staff_role?
    employer_staff_roles.present? and employer_staff_roles.active.present?
  end

  def active_employer_staff_roles
    employer_staff_roles.present? ? employer_staff_roles.active : []
  end

  def has_multiple_roles?
    consumer_role.present? && active_employee_roles.present?
  end

  def residency_eligible?
    no_dc_address and no_dc_address_reason.present?
  end

  def is_dc_resident?
    return false if no_dc_address == true && no_dc_address_reason.blank?
    return true if no_dc_address == true && no_dc_address_reason.present?

    address_to_use = addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
    addresses.each{|address| return true if address.kind == address_to_use && address.state == 'DC'}
    return false
  end

  class << self
    def default_search_order
      [[:last_name, 1],[:first_name, 1]]
    end

    def search_hash(s_str)
      clean_str = s_str.strip
      s_rex = Regexp.new(Regexp.escape(clean_str), true)
      {
        "$or" => ([
          {"first_name" => s_rex},
          {"last_name" => s_rex},
          {"hbx_id" => s_rex},
          {"encrypted_ssn" => encrypt_ssn(s_rex)}
        ] + additional_exprs(clean_str))
      }
    end

    def additional_exprs(clean_str)
      additional_exprs = []
      if clean_str.include?(" ")
        parts = clean_str.split(" ").compact
        first_re = Regexp.new(Regexp.escape(parts.first), true)
        last_re = Regexp.new(Regexp.escape(parts.last), true)
        additional_exprs << {:first_name => first_re, :last_name => last_re}
      end
      additional_exprs
    end

    def search_first_name_last_name_npn(s_str, query=self)
      clean_str = s_str.strip
      s_rex = Regexp.new(Regexp.escape(s_str.strip), true)
      query.where({
        "$or" => ([
          {"first_name" => s_rex},
          {"last_name" => s_rex},
          {"broker_role.npn" => s_rex}
          ] + additional_exprs(clean_str))
        })
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
      return false
    end

    def find_by_ssn(ssn)
      Person.where(encrypted_ssn: Person.encrypt_ssn(ssn)).first
    end

    def dob_change_implication_on_active_enrollments(person, new_dob)
      # This method checks if there is a premium implication in all active enrollments when a persons DOB is changed.
      # Returns a hash with Key => HbxEnrollment ID and, Value => true if  enrollment has Premium Implication.
      premium_impication_for_enrollment = Hash.new
      active_enrolled_hbxs = person.primary_family.active_household.hbx_enrollments.active.enrolled_and_renewal

      # Iterate over each enrollment and check if there is a Premium Implication based on the following rule:
      # Rule: There are Implications when DOB changes makes anyone in the household a different age on the day coverage started UNLESS the 
      #       change is all within the 0-20 age range or all within the 61+ age range (20 >= age <= 61)
      active_enrolled_hbxs.each do |hbx|
        new_temp_person = person.dup
        new_temp_person.dob = Date.strptime(new_dob.to_s, '%m/%d/%Y')
        new_age     = new_temp_person.age_on(hbx.effective_on)  # age with the new DOB on the day coverage started
        current_age = person.age_on(hbx.effective_on)           # age with the current DOB on the day coverage started

        next if new_age == current_age # No Change in age -> No Premium Implication

        # No Implication when the change is all within the 0-20 age range or all within the 61+ age range
        if ( current_age.between?(0,20) && new_age.between?(0,20) ) || ( current_age >= 61 && new_age >= 61 )
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

      raise ArgumentError, "must provide an ssn or first_name/last_name/dob or both" if (ssn_query.blank? && (dob_query.blank? || last_name.blank? || first_name.blank?))

      matches = Array.new
      matches.concat Person.active.where(encrypted_ssn: encrypt_ssn(ssn_query)).to_a unless ssn_query.blank?
      #matches.concat Person.where(last_name: last_name, dob: dob_query).active.to_a unless (dob_query.blank? || last_name.blank?)
      if first_name.present? && last_name.present? && dob_query.present?
        first_exp = /^#{first_name}$/i
        last_exp = /^#{last_name}$/i
        matches.concat Person.where(dob: dob_query, last_name: last_exp, first_name: first_exp).active.to_a.select{|person| person.ssn.blank? || ssn_query.blank?}
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
      staff_had_role = self.where(:'employer_staff_roles.employer_profile_id' => employer_profile.id)
      staff_had_role.map(&:employer_staff_roles).flatten.select{|r|r.is_active?}.map(&:person)
    end

    def staff_for_employer_including_pending(employer_profile)
      self.where(:employer_staff_roles => {
        '$elemMatch' => {
            employer_profile_id: employer_profile.id,
            :aasm_state.ne => :is_closed
        }
        })
    end

    # Adds employer staff role to person
    # Returns status and message if failed
    # Returns status and person if successful
    def add_employer_staff_role(first_name, last_name, dob, email, employer_profile)
      person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

      return false, 'Person count too high, please contact HBX Admin' if person.count > 1
      return false, 'Person does not exist on the HBX Exchange' if person.count == 0

      employer_staff_role = EmployerStaffRole.create(person: person.first, employer_profile_id: employer_profile._id)
      employer_staff_role.save
      return true, person.first
    end

    # Sets employer staff role to inactive
    # Returns false if person not found
    # Returns false if employer staff role not matches
    # Returns true is role was marked inactive
    def deactivate_employer_staff_role(person_id, employer_profile_id)

      begin
        person = Person.find(person_id)
      rescue
        return false, 'Person not found'
      end
      if role = person.employer_staff_roles.detect{|role| role.employer_profile_id.to_s == employer_profile_id.to_s}
        role.update_attributes!(:aasm_state => :is_closed)
        return true, 'Employee Staff Role is inactive'
      else
        return false, 'No matching employer staff role'
      end
    end

  end

  # HACK
  # FIXME
  # TODO: Move this out of here
  attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status

  attr_accessor :is_consumer_role

  before_save :assign_citizen_status_from_consumer_role

  def assign_citizen_status_from_consumer_role
    if is_consumer_role.to_s=="true"
      assign_citizen_status
    end
  end

  def us_citizen=(val)
    @us_citizen = (val.to_s == "true")
    @naturalized_citizen = false if val.to_s == "false"
  end

  def naturalized_citizen=(val)
    @naturalized_citizen = (val.to_s == "true")
  end

  def indian_tribe_member=(val)
    @indian_tribe_member = (val.to_s == "true")
  end

  def eligible_immigration_status=(val)
    @eligible_immigration_status = (val.to_s == "true")
  end

  def us_citizen
    return @us_citizen if !@us_citizen.nil?
    return nil if citizen_status.blank?
    @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(citizen_status)
  end

  def naturalized_citizen
    return @naturalized_citizen if !@naturalized_citizen.nil?
    return nil if citizen_status.blank?
    @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == citizen_status)
  end

  def indian_tribe_member
    return @indian_tribe_member if !@indian_tribe_member.nil?
    return nil if citizen_status.blank?
    @indian_tribe_member ||= (::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS == citizen_status)
  end

  def eligible_immigration_status
    return @eligible_immigration_status if !@eligible_immigration_status.nil?
    return nil if @us_citizen.nil?
    return nil if @us_citizen
    return nil if citizen_status.blank?
    @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == citizen_status)
  end

  def assign_citizen_status
    if indian_tribe_member
      self.citizen_status = ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS
    elsif naturalized_citizen
      self.citizen_status = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS
    elsif us_citizen
      self.citizen_status = ::ConsumerRole::US_CITIZEN_STATUS
    elsif eligible_immigration_status
      self.citizen_status = ::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS
    elsif (!eligible_immigration_status.nil?)
      self.citizen_status = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
    elsif
      self.citizen_status = nil
    end
  end

  def agent?
    agent = self.csr_role || self.assister_role || self.broker_role || self.hbx_staff_role || self.general_agency_staff_roles.present?
    !!agent
  end

  def contact_info(email_address, area_code, number, extension)
    if email_address.present?
      email = emails.detect{|mail|mail.kind == 'work'}
      if email
        email.update_attributes!(address: email_address)
      else
        email= Email.new(kind: 'work', address: email_address)
        emails.append(email)
        self.update_attributes!(emails: emails)
        save!
      end
    end
    phone = phones.detect{|p|p.kind == 'work'}
    if phone
      phone.update_attributes!(area_code: area_code, number: number, extension: extension)
    else
      phone = Phone.new(kind: 'work', area_code: area_code, number: number, extension: extension)
      phones.append(phone)
      self.update_attributes!(phones: phones)
      save!
    end
  end

  def generate_family_search
    ::MapReduce::FamilySearchForPerson.populate_for(self)
  end

  def set_consumer_role_url
    if consumer_role.present? && user.present?
      if primary_family.present? && primary_family.active_household.present? && primary_family.active_household.hbx_enrollments.where(kind: "individual", is_active: true).present?
        consumer_role.update_attribute(:bookmark_url, "/families/home") if user.identity_verified? && user.idp_verified && (addresses.present? || no_dc_address.present? || no_dc_address_reason.present?)
      end
    end
  end

  private
  def is_ssn_composition_correct?
    # Invalid compositions:
    #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
    #   00 in the group number (fourth and fifth digit); or
    #   0000 in the serial number (last four digits)

    if ssn.present?
      invalid_area_numbers = %w(000 666)
      invalid_area_range = 900..999
      invalid_group_numbers = %w(00)
      invalid_serial_numbers = %w(0000)

      return false if ssn.to_s.blank?
      return false if invalid_area_numbers.include?(ssn.to_s[0,3])
      return false if invalid_area_range.include?(ssn.to_s[0,3].to_i)
      return false if invalid_group_numbers.include?(ssn.to_s[3,2])
      return false if invalid_serial_numbers.include?(ssn.to_s[5,4])
    end

    true
  end

  def create_inbox
    welcome_subject = "Welcome to #{Settings.site.short_name}"
    welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    mailbox = Inbox.create(recipient: self)
    mailbox.messages.create(subject: welcome_subject, body: welcome_body, from: "#{Settings.site.short_name}")
  end

  def update_full_name
    full_name
  end

  def no_changing_my_user
    if self.persisted? && self.user_id_changed?
      old_user, new_user= self.user_id_change
      return if old_user.blank?
      if (old_user != new_user)
        errors.add(:base, "you may not change the user_id of a person once it has been set and saved")
      end
    end
  end

  # Verify basic date rules
  def date_functional_validations
    date_of_birth_is_past
    date_of_death_is_blank_or_past
    date_of_death_follows_date_of_birth
  end

  def date_of_death_is_blank_or_past
    return unless self.date_of_death.present?
    errors.add(:date_of_death, "future date: #{self.date_of_death} is invalid date of death") if TimeKeeper.date_of_record < self.date_of_death
  end

  def date_of_birth_is_past
    return unless self.dob.present?
    errors.add(:dob, "future date: #{self.dob} is invalid date of birth") if TimeKeeper.date_of_record < self.dob
  end

  def date_of_death_follows_date_of_birth
    return unless self.date_of_death.present? && self.dob.present?

    if self.date_of_death < self.dob
      errors.add(:date_of_death, "date of death cannot preceed date of birth")
      errors.add(:dob, "date of birth cannot follow date of death")
    end
  end
end
