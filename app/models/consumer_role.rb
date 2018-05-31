class ConsumerRole
  RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.residency.verification_request"

  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include Acapi::Notifiers
  include AASM
  include Mongoid::Attributes::Dynamic
  include StateTransitionPublisher
  include Mongoid::History::Trackable
  include DocumentsVerificationStatus

  embedded_in :person

  VLP_AUTHORITY_KINDS = %w(ssa dhs hbx curam)
  NATURALIZED_CITIZEN_STATUS = "naturalized_citizen"
  INDIAN_TRIBE_MEMBER_STATUS = "indian_tribe_member"
  US_CITIZEN_STATUS = "us_citizen"
  NOT_LAWFULLY_PRESENT_STATUS = "not_lawfully_present_in_us"
  ALIEN_LAWFULLY_PRESENT_STATUS = "alien_lawfully_present"
  INELIGIBLE_CITIZEN_VERIFICATION = %w(not_lawfully_present_in_us non_native_not_lawfully_present_in_us)

  SSN_VALIDATION_STATES = %w(na valid outstanding pending)
  NATIVE_VALIDATION_STATES = %w(na valid outstanding pending)
  LOCAL_RESIDENCY_VALIDATION_STATES = %w(attested valid outstanding pending) #attested state is used for people with active enrollments before locale residency verification was turned on
  VERIFICATION_SENSITIVE_ATTR = %w(first_name last_name ssn us_citizen naturalized_citizen eligible_immigration_status dob indian_tribe_member)

  US_CITIZEN_STATUS_KINDS = %W(
  us_citizen
  naturalized_citizen
  indian_tribe_member
  )
  CITIZEN_STATUS_KINDS = %w(
      us_citizen
      naturalized_citizen
      alien_lawfully_present
      lawful_permanent_resident
      undocumented_immigrant
      not_lawfully_present_in_us
      non_native_not_lawfully_present_in_us
      ssn_pass_citizenship_fails_with_SSA
      non_native_citizen
  )

  ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
      us_citizen
      naturalized_citizen
      indian_tribe_member
  )

  # FiveYearBarApplicabilityIndicator ??
  field :five_year_bar, type: Boolean, default: false
  field :requested_coverage_start_date, type: Date, default: TimeKeeper.date_of_record
  field :aasm_state

  delegate :citizen_status, :citizenship_result,:vlp_verified_date, :vlp_authority, :vlp_document_id, to: :lawful_presence_determination_instance
  delegate :citizen_status=, :citizenship_result=,:vlp_verified_date=, :vlp_authority=, :vlp_document_id=, to: :lawful_presence_determination_instance

  field :is_applicant, type: Boolean  # Consumer is applying for benefits coverage
  field :birth_location, type: String
  field :marital_status, type: String
  field :is_active, type: Boolean, default: true
  field :is_applying_coverage, type: Boolean, default: true

  field :raw_event_responses, type: Array, default: [] #e.g. [{:lawful_presence_response => payload}]
  field :bookmark_url, type: String, default: nil
  field :contact_method, type: String, default: "Paper and Electronic communications"
  field :language_preference, type: String, default: "English"

  field :ssn_validation, type: String, default: "pending"
  validates_inclusion_of :ssn_validation, :in => SSN_VALIDATION_STATES, :allow_blank => false

  field :native_validation, type: String, default: -> {"na"}
  validates_inclusion_of :native_validation, :in => NATIVE_VALIDATION_STATES, :allow_blank => false

  # DC residency
  field :is_state_resident, type: Boolean, default: nil
  field :residency_determined_at, type: DateTime
  field :local_residency_validation, type: String, default: nil
  validates_inclusion_of :local_residency_validation, :in => LOCAL_RESIDENCY_VALIDATION_STATES, :allow_blank => true

  field :ssn_update_reason, type: String
  field :lawful_presence_update_reason, type: Hash
  field :native_update_reason, type: String
  field :residency_update_reason, type: String

  #rejection flags for verification types
  field :ssn_rejected, type: Boolean, default: false
  field :native_rejected, type: Boolean, default: false
  field :lawful_presence_rejected, type: Boolean, default: false
  field :residency_rejected, type: Boolean, default: false

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn,    :ssn=,    to: :person, allow_nil: true
  delegate :no_ssn,    :no_ssn=,    to: :person, allow_nil: true
  delegate :dob,    :dob=,    to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  delegate :is_incarcerated,    :is_incarcerated=,   to: :person, allow_nil: true

  delegate :race,               :race=,              to: :person, allow_nil: true
  delegate :ethnicity,          :ethnicity=,         to: :person, allow_nil: true
  delegate :is_disabled,        :is_disabled=,       to: :person, allow_nil: true
  delegate :tribal_id,          :tribal_id=,         to: :person, allow_nil: true

  embeds_many :documents, as: :documentable
  embeds_many :vlp_documents, as: :documentable do
    def uploaded
      @target.select{|document| document.identifier }
    end
  end
  embeds_many :workflow_state_transitions, as: :transitional
  embeds_many :special_verifications, cascade_callbacks: true, validate: true
  embeds_many :verification_type_history_elements

  accepts_nested_attributes_for :person, :workflow_state_transitions, :vlp_documents

  validates_presence_of :dob, :gender, :is_applicant
  #validate :ssn_or_no_ssn

  validates :vlp_authority,
    allow_blank: true,
    inclusion: { in: VLP_AUTHORITY_KINDS, message: "%{value} is not a valid identity authority" }

  validates :citizen_status,
    allow_blank: true,
    inclusion: { in: CITIZEN_STATUS_KINDS + ACA_ELIGIBLE_CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" }

  validates :citizenship_result,
    allow_blank: true,
    inclusion: { in: CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" }

  scope :all_under_age_twenty_six, ->{ gt(:'dob' => (TimeKeeper.date_of_record - 26.years))}
  scope :all_over_age_twenty_six,  ->{lte(:'dob' => (TimeKeeper.date_of_record - 26.years))}

  # TODO: Add scope that accepts age range
  scope :all_over_or_equal_age, ->(age) {lte(:'dob' => (TimeKeeper.date_of_record - age.years))}
  scope :all_under_or_equal_age, ->(age) {gte(:'dob' => (TimeKeeper.date_of_record - age.years))}

  alias_method :is_state_resident?, :is_state_resident
  alias_method :is_incarcerated?,   :is_incarcerated

  embeds_one :lawful_presence_determination, as: :ivl_role

  embeds_many :local_residency_responses, class_name:"EventResponse"
  embeds_many :local_residency_requests, class_name:"EventRequest"

  after_initialize :setup_lawful_determination_instance

  before_validation :ensure_validation_states, on: [:create, :update]

  track_history   :on => [:five_year_bar,
                          :aasm_state,
                          :marital_status,
                          :ssn_validation,
                          :native_validation,
                          :is_state_resident,
                          :local_residency_validation,
                          :ssn_update_reason,
                          :lawful_presence_update_reason,
                          :native_update_reason,
                          :residency_update_reason,
                          :is_applying_coverage,
                          :ssn_rejected,
                          :native_rejected,
                          :lawful_presence_rejected,
                          :residency_rejected],
                  :scope => :person,
                  :modifier_field => :modifier,
                  :version_field => :tracking_version,
                  :track_create  => true,    # track document creation, default is false
                  :track_update  => true,    # track document updates, default is true
                  :track_destroy => true

  # used to track history verification actions can be used on any top node model to build history of changes.
  # in this case consumer role taken as top node model instead of family member bz all verification functionality tied to consumer role model
  # might be encapsulated into new verification model further with verification code refactoring
  embeds_many :history_action_trackers, as: :history_trackable

  #list of the collections we want to track under consumer role model
  COLLECTIONS_TO_TRACK = %w- Person consumer_role vlp_documents lawful_presence_determination hbx_enrollments -

  def ivl_coverage_selected
    if unverified?
      coverage_purchased!
    end
  end

  def ssn_or_no_ssn
    errors.add(:base, 'Provide SSN or check No SSN') unless ssn.present? || no_ssn == '1'
  end

  def start_residency_verification_process
    notify(RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => self.person})
  end

  def setup_lawful_determination_instance
    unless self.lawful_presence_determination.present?
      self.lawful_presence_determination = LawfulPresenceDetermination.new
    end
  end

  def lawful_presence_determination_instance
    setup_lawful_determination_instance
    self.lawful_presence_determination
  end

  def is_aca_enrollment_eligible?
    is_hbx_enrollment_eligible? &&
      Person::ACA_ELIGIBLE_CITIZEN_STATUS_KINDS.include?(citizen_status)
  end

  #check if consumer has uploaded documents for verification type
  def has_docs_for_type?(type)
    self.vlp_documents.any?{ |doc| doc.verification_type == type && doc.identifier }
  end

  def has_outstanding_documents?
    self.vlp_documents.any? {|doc| verification_type_status(doc.verification_type, self.person) == "outstanding" }
  end

  #use this method to check what verification types needs to be included to the notices
  def outstanding_verification_types
    self.person.verification_types.find_all do |type|
      self.is_type_outstanding?(type)
    end
  end

  def all_types_verified?
    person.verification_types.all?{ |type| is_type_verified?(type) }
  end

  #check verification type status
  def is_type_outstanding?(type)
    case type
      when "DC Residency"
        residency_denied? && !has_docs_for_type?(type) && local_residency_outstanding?
      when 'Social Security Number'
        !ssn_verified? && !has_docs_for_type?(type)
      when 'American Indian Status'
        !native_verified? && !has_docs_for_type?(type)
      else
        !lawful_presence_authorized? && !has_docs_for_type?(type)
    end
  end

  def local_residency_outstanding?
    self.local_residency_validation == 'outstanding'
  end

  def ssn_verified?
    ["na", "valid"].include?(self.ssn_validation)
  end

  def ssn_pending?
    self.ssn_validation == "pending"
  end

  def ssn_outstanding?
    self.ssn_validation == "outstanding"
  end

  def lawful_presence_verified?
    self.lawful_presence_determination.verification_successful?
  end

  def is_hbx_enrollment_eligible?
    is_state_resident? && !is_incarcerated?
  end

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  def families
    Family.by_consumerRole(self)
  end

  def phone
    parent.phones.detect { |phone| phone.kind == "home" }
  end

  def email
    parent.emails.detect { |email| email.kind == "home" }
  end

  def home_address
    addresses.detect { |adr| adr.kind == "home" }
  end

  def mailing_address
    addresses.detect { |adr| adr.kind == "mailing" } || home_address
  end

  def billing_address
    addresses.detect { |adr| adr.kind == "billing" } || home_address
  end

  def self.find(consumer_role_id)
    consumer_role_id = BSON::ObjectId.from_string(consumer_role_id) if consumer_role_id.is_a? String
    @person_find = Person.where("consumer_role._id" => consumer_role_id).first.consumer_role unless consumer_role_id.blank?
  end

  def self.all
    Person.all_consumer_roles
  end


  def is_active?
    self.is_active
  end

  def self.naturalization_document_types
    VlpDocument::NATURALIZATION_DOCUMENT_TYPES
  end

  # RIDP and Verify Lawful Presence workflow.  IVL Consumer primary applicant must be in identity_verified state
  # to proceed with application.  Each IVL Consumer enrolled for benefit coverage must (eventually) pass
  def alien_number
    vlp_documents.select{|doc| doc.alien_number.present? }.first.try(:alien_number)
  end

  def i94_number
    vlp_documents.select{|doc| doc.i94_number.present? }.first.try(:i94_number)
  end

  def citizenship_number
    vlp_documents.select{|doc| doc.citizenship_number.present? }.first.try(:citizenship_number)
  end

  def visa_number
    vlp_documents.select{|doc| doc.visa_number.present? }.first.try(:visa_number)
  end

  def sevis_id
    vlp_documents.select{|doc| doc.sevis_id.present? }.first.try(:sevis_id)
  end

  def naturalization_number
    vlp_documents.select{|doc| doc.naturalization_number.present? }.first.try(:naturalization_number)
  end

  def receipt_number
    vlp_documents.select{|doc| doc.receipt_number.present? }.first.try(:receipt_number)
  end

  def passport_number
    vlp_documents.select{|doc| doc.passport_number.present? }.first.try(:passport_number)
  end

  def has_i327?
    vlp_documents.any?{|doc| doc.subject == "I-327 (Reentry Permit)" }
  end

  def has_i571?
    vlp_documents.any?{|doc| doc.subject == "I-551 (Permanent Resident Card)" }
  end

  def has_cert_of_citizenship?
    vlp_documents.any?{|doc| doc.subject == "Certificate of Citizenship" }
  end

  def has_cert_of_naturalization?
    vlp_documents.any?{|doc| doc.subject == "Naturalization Certificate" }
  end

  def has_temp_i551?
    vlp_documents.any?{|doc| doc.subject == "Temporary I-551 Stamp (on passport or I-94)" }
  end

  def has_i94?
    vlp_documents.any?{|doc| doc.subject == "I-94 (Arrival/Departure Record)" || doc.subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport"}
  end

  def has_i20?
    vlp_documents.any?{|doc| doc.subject == "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)" }
  end

  def has_ds2019?
    vlp_documents.any?{|doc| doc.subject == "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)" }
  end

  def i551
    vlp_documents.select{|doc| doc.subject == "I-551 (Permanent Resident Card)" && doc.receipt_number.present? }.first
  end

  def i766
    vlp_documents.select{|doc| doc.subject == "I-766 (Employment Authorization Card)" && doc.receipt_number.present? && doc.expiration_date.present? }.first
  end

  def mac_read_i551
    vlp_documents.select{|doc| doc.subject == "Machine Readable Immigrant Visa (with Temporary I-551 Language)" && doc.issuing_country.present? && doc.passport_number.present? && doc.expiration_date.present? }.first
  end

  def foreign_passport_i94
    vlp_documents.select{|doc| doc.subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" && doc.issuing_country.present? && doc.passport_number.present? && doc.expiration_date.present? }.first
  end

  def foreign_passport
    vlp_documents.select{|doc| doc.subject == "Unexpired Foreign Passport" && doc.issuing_country.present? && doc.passport_number.present? && doc.expiration_date.present? }.first
  end

  def case1
    vlp_documents.select{|doc| doc.subject == "Other (With Alien Number)" }.first
  end

  def case2
    vlp_documents.select{|doc| doc.subject == "Other (With I-94 Number)" }.first
  end

  def can_receive_paper_communication?
    ["Only Paper communication", "Paper and Electronic communications"].include?(contact_method)
  end

  def can_receive_electronic_communication?
    ["Only Electronic communications", "Paper and Electronic communications"].include?(contact_method)
  end

  ## TODO: Move RIDP to user model
  aasm do
    state :unverified, initial: true
    state :ssa_pending
    state :dhs_pending
    state :verification_outstanding
    state :sci_verified #sci => ssn citizenship immigration
    state :fully_verified
    state :verification_period_ended

    before_all_events :ensure_validation_states

    event :import, :after => [:record_transition, :notify_of_eligibility_change, :update_all_verification_types] do
      transitions from: :unverified, to: :fully_verified
      transitions from: :ssa_pending, to: :fully_verified
      transitions from: :dhs_pending, to: :fully_verified
      transitions from: :verification_outstanding, to: :fully_verified
      transitions from: :verification_period_ended, to: :fully_verified
      transitions from: :sci_verified, to: :fully_verified
      transitions from: :fully_verified, to: :fully_verified
    end

    event :coverage_purchased, :after => [:record_transition, :notify_of_eligibility_change, :invoke_residency_verification!]  do
      transitions from: :unverified, to: :verification_outstanding, :guard => :native_no_ssn?, :after => [:fail_ssa_for_no_ssn]
      transitions from: :unverified, to: :dhs_pending, :guards => [:call_dhs?], :after => [:invoke_verification!]
      transitions from: :unverified, to: :ssa_pending, :guards => [:call_ssa?], :after => [:invoke_verification!]
    end

    event :coverage_purchased_no_residency, :after => [:record_transition, :notify_of_eligibility_change]  do
      transitions from: :unverified, to: :verification_outstanding, :guard => :native_no_ssn?, :after => [:fail_ssa_for_no_ssn]
      transitions from: :unverified, to: :dhs_pending, :guards => [:call_dhs?], :after => [:invoke_verification!]
      transitions from: :unverified, to: :ssa_pending, :guards => [:call_ssa?], :after => [:invoke_verification!]
    end


    event :ssn_invalid, :after => [:fail_ssn, :fail_lawful_presence, :record_transition, :notify_of_eligibility_change] do
      transitions from: :ssa_pending, to: :verification_outstanding
    end

    event :ssn_valid_citizenship_invalid, :after => [:pass_ssn, :record_transition, :notify_of_eligibility_change, :fail_lawful_presence] do
      transitions from: :ssa_pending, to: :verification_outstanding, :guard => :is_native?, :after => [:fail_lawful_presence]
      transitions from: :ssa_pending, to: :dhs_pending, :guard => :is_non_native?, :after => [:invoke_dhs, :record_partial_pass]
    end

    event :ssn_valid_citizenship_valid, :guard => :call_ssa?, :after => [:pass_ssn, :pass_lawful_presence, :record_transition, :notify_of_eligibility_change] do
      transitions from: [:unverified, :ssa_pending, :verification_outstanding], to: :verification_outstanding, :guard => :residency_denied?
      transitions from: [:unverified, :ssa_pending, :verification_outstanding], to: :sci_verified, :guard => :residency_pending?
      transitions from: [:unverified, :ssa_pending, :verification_outstanding], to: :fully_verified, :guard => :residency_verified?
    end

    event :fail_dhs, :after => [:fail_lawful_presence, :record_transition, :notify_of_eligibility_change] do
      transitions from: :dhs_pending, to: :verification_outstanding
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :pass_dhs, :guard => :is_non_native?, :after => [:pass_lawful_presence, :record_transition, :notify_of_eligibility_change] do
      transitions from: [:unverified, :dhs_pending, :verification_outstanding], to: :verification_outstanding, :guard => :residency_denied?
      transitions from: [:unverified, :dhs_pending, :verification_outstanding], to: :sci_verified, :guard => :residency_pending?
      transitions from: [:unverified, :dhs_pending, :verification_outstanding], to: :fully_verified, :guard => :residency_verified?
    end

    event :pass_residency, :after => [:mark_residency_authorized, :record_transition] do
      transitions from: :unverified, to: :unverified
      transitions from: :ssa_pending, to: :ssa_pending
      transitions from: :dhs_pending, to: :dhs_pending
      transitions from: :sci_verified, to: :fully_verified
      transitions from: :verification_outstanding, to: :fully_verified, :guards => [:ssn_verified?, :lawful_presence_verified?]
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :fail_residency, :after => [:mark_residency_denied, :record_transition] do
      transitions from: :unverified, to: :verification_outstanding
      transitions from: :ssa_pending, to: :ssa_pending
      transitions from: :dhs_pending, to: :dhs_pending
      transitions from: :sci_verified, to: :verification_outstanding
      transitions from: :verification_outstanding, to: :verification_outstanding
      transitions from: :fully_verified, to: :verification_outstanding
    end

    event :trigger_residency, :after => [:mark_residency_pending, :record_transition, :start_residency_verification_process] do
      transitions from: :ssa_pending, to: :ssa_pending
      transitions from: :dhs_pending, to: :dhs_pending
      transitions from: :sci_verified, to: :sci_verified
      transitions from: :verification_outstanding, to: :verification_outstanding
      transitions from: :fully_verified, to: :sci_verified
    end

    #this event rejecting the status if admin rejects any verification type but it DOESN'T work backwards - we don't move all the types to unverified by triggering this event
    event :reject, :after => [:record_transition, :notify_of_eligibility_change] do
      transitions from: :unverified, to: :verification_outstanding
      transitions from: :ssa_pending, to: :verification_outstanding
      transitions from: :dhs_pending, to: :verification_outstanding
      transitions from: :verification_outstanding, to: :verification_outstanding
      transitions from: :fully_verified, to: :verification_outstanding
      transitions from: :verification_period_ended, to: :verification_outstanding
    end

    event :revert, :after => [:revert_ssn, :revert_lawful_presence, :notify_of_eligibility_change, :record_transition] do
      transitions from: :unverified, to: :unverified
      transitions from: :ssa_pending, to: :unverified
      transitions from: :dhs_pending, to: :unverified
      transitions from: :verification_outstanding, to: :unverified
      transitions from: :fully_verified, to: :unverified
      transitions from: :sci_verified, to: :unverified
      transitions from: :verification_period_ended, to: :unverified
    end

    event :verifications_backlog, :after => [:record_transition] do
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :first_verifications_reminder, :after => [:record_transition] do
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :second_verifications_reminder, :after => [:record_transition] do
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :third_verifications_reminder, :after => [:record_transition] do
      transitions from: :verification_outstanding, to: :verification_outstanding
    end

    event :fourth_verifications_reminder, :after => [:record_transition] do
      transitions from: :verification_outstanding, to: :verification_outstanding
    end
  end

  def invoke_verification!(*args)
    if person.ssn || is_native?
      invoke_ssa
    else
      invoke_dhs
    end
  end

  def verify_ivl_by_admin(*args)
    if sci_verified?
      pass_residency!
    else
      if person.ssn || is_native?
        self.ssn_valid_citizenship_valid! verification_attr(args.first)
      else
        self.pass_dhs! verification_attr(args.first)
      end
    end
  end

  def update_by_person(*args)
    person.consumer_role.update_attributes(is_applying_coverage: args[0]["is_applying_coverage"])
    args[0].delete("is_applying_coverage")
    person.update_attributes(args[0])
  end

  def build_nested_models_for_person
    ["home", "mobile"].each do |kind|
      person.phones.build(kind: kind) if person.phones.select { |phone| phone.kind == kind }.blank?
    end

    (Address::KINDS - ['work']).each do |kind|
      person.addresses.build(kind: kind) if person.addresses.select { |address| address.kind.to_s.downcase == kind }.blank?
    end

    Email::KINDS.each do |kind|
      person.emails.build(kind: kind) if person.emails.select { |email| email.kind == kind }.blank?
    end
  end

  def find_document(subject)
    subject_doc = vlp_documents.detect do |documents|
      documents.subject.eql?(subject)
    end

    subject_doc || vlp_documents.build({subject:subject})
  end

  # collect all vlp documents for person and all dependents.
  # return the one with matching key
  def find_vlp_document_by_key(key)
    candidate_vlp_documents = vlp_documents
    if person.primary_family.present?
      person.primary_family.family_members.flat_map(&:person).each do |family_person|
        next unless family_person.consumer_role.present?
        candidate_vlp_documents << family_person.consumer_role.vlp_documents
      end
      candidate_vlp_documents.uniq!
    end

    return nil if candidate_vlp_documents.nil?

    candidate_vlp_documents.detect do |document|
      next if document.identifier.blank?
      doc_key = document.identifier.split('#').last
      doc_key == key
    end
  end

  def latest_active_tax_household_with_year(year, family)
    family.latest_household.latest_active_tax_household_with_year(year)
  rescue => e
    log("#4287 person_id: #{person.try(:id)}", {:severity => 'error'})
    nil
  end

  def is_native?
    US_CITIZEN_STATUS == citizen_status
  end

  def is_non_native?
    !is_native?
  end

  def no_ssn?
    person.ssn.nil?
  end

  def ssn_applied?
    !no_ssn?
  end

  def call_ssa?
    is_native? || ssn_applied?
  end

  def call_dhs?
    no_ssn? && is_non_native?
  end

  def native_no_ssn?
    is_native? && no_ssn?
  end

  def check_for_critical_changes(person_params, family)
    if person_params.select{|k,v| VERIFICATION_SENSITIVE_ATTR.include?(k) }.any?{|field,v| sensitive_information_changed(field, person_params)}
      redetermine_verification!(verification_attr) if family.person_has_an_active_enrollment?(person)
    end

    trigger_residency! if can_trigger_residency?(person_params["no_dc_address"], family)
  end

  def can_trigger_residency?(no_dc_address, family) # trigger for change in address
    person.age_on(TimeKeeper.date_of_record) > 18 &&
    person.no_dc_address &&
    no_dc_address == "false" &&
    family.person_has_an_active_enrollment?(person)
  end

  def add_type_history_element(params)
    verification_type_history_elements<<VerificationTypeHistoryElement.new(params)
  end

  def can_start_residency_verification? # initial trigger check for coverage purchase
    !person.no_dc_address && person.age_on(TimeKeeper.date_of_record) > 18
  end

  def invoke_residency_verification!
    if can_start_residency_verification?
      mark_residency_pending
      start_residency_verification_process
    end
  end

  #class methods
  class << self
    #this method will be used to check 90 days verification period for outstanding verification
    def advance_day(check_date)
      #handle all outstanding consumer who is unverified more than 90 days
    end
  end

  private
  def notify_of_eligibility_change(*args)
    CoverageHousehold.update_individual_eligibilities_for(self)
  end

  def mark_residency_denied(*args)
    update_attributes(:residency_determined_at => DateTime.now,
                      :is_state_resident => false,
                      :local_residency_validation => "outstanding")
  end

  def mark_residency_pending(*args)
    update_attributes(:residency_determined_at => DateTime.now,
                      :is_state_resident => nil,
                      :local_residency_validation => "pending")
  end

  def mark_residency_authorized(*args)
    update_attributes(:residency_determined_at => DateTime.now,
                      :is_state_resident => true,
                      :local_residency_validation => "valid")
  end

  def lawful_presence_pending?
    lawful_presence_determination.verification_pending?
  end

  def lawful_presence_outstanding?
    lawful_presence_determination.verification_outstanding?
  end

  def lawful_presence_authorized?
    lawful_presence_determination.verification_successful?
  end

  def residency_pending?
    local_residency_validation == "pending" || is_state_resident.nil?
  end

  def residency_denied?
    (!is_state_resident.nil?) && (!is_state_resident)
  end

  def residency_verified?
    is_state_resident? || residency_attested?
  end

  def residency_attested?
    local_residency_validation == "attested" || person.residency_eligible? || person.age_on(TimeKeeper.date_of_record) <= 18
  end

  def citizenship_verified?
    lawful_presence_authorized?
  end

  def native_verified?
    native_validation == "valid"
  end

  def native_outstanding?
    native_validation == "outstanding"
  end

  def indian_conflict?
    citizen_status == "indian_tribe_member"
  end

  def mark_doc_type_uploaded(v_type)
    case v_type
      when "Social Security Number"
        update_attributes(:ssn_rejected => false)
      when "Citizenship"
        update_attributes(:lawful_presence_rejected => false)
      when "Immigration status"
        update_attributes(:lawful_presence_rejected => false)
      when "American Indian Status"
        update_attributes(:native_rejected => false)
      when "DC Residency"
        update_attributes(:residency_rejected => false)
    end
  end

  def invoke_ssa
    lawful_presence_determination.start_ssa_process
  end

  def invoke_dhs
    lawful_presence_determination.start_vlp_process(requested_coverage_start_date)
  end

  def pass_ssn(*args)
    self.update_attributes!(ssn_validation: "valid")
  end

  def fail_ssn(*args)
    self.update_attributes!(
      ssn_validation: "outstanding"
    )
  end

  def fail_ssa_for_no_ssn(*args)
    self.update_attributes!(
      ssn_validation: "outstanding",
      ssn_update_reason: "no_ssn_for_native"
    )
  end

  def pass_lawful_presence(*args)
    lawful_presence_determination.authorize!(*args)
  end

  def record_partial_pass(*args)
    lawful_presence_determination.update_attributes!(:citizenship_result => "ssn_pass_citizenship_fails_with_SSA")
  end

  def fail_lawful_presence(*args)
    lawful_presence_determination.deny!(*args)
  end

  def revert_ssn
    update_attributes(:ssn_validation => "pending")
  end

  def revert_native
    update_attributes(:native_validation => "pending")
  end

  def revert_lawful_presence(*args)
    self.lawful_presence_determination.revert!(*args)
  end

  def update_all_verification_types(*args)
    person.verification_types.each do |v_type|
      update_verification_type(v_type, "fully verified by curam/migration", lawful_presence_determination.try(:vlp_authority))
    end
  end

  def admin_verification_action(admin_action, v_type, update_reason)
    case admin_action
      when "verify"
        update_verification_type(v_type, update_reason)
      when "return_for_deficiency"
        return_doc_for_deficiency(v_type, update_reason)
    end
  end

  def return_doc_for_deficiency(v_type, update_reason, *authority)
    case v_type
      when "DC Residency"
        update_attributes(:residency_update_reason => update_reason, :residency_rejected => true)
        mark_residency_denied
      when "Social Security Number"
        update_attributes(:ssn_validation => "outstanding", :ssn_update_reason => update_reason, :ssn_rejected => true)
      when "American Indian Status"
        update_attributes(:native_validation => "outstanding", :native_update_reason => update_reason, :native_rejected => true)
      else
        lawful_presence_determination.deny!(verification_attr(authority.first))
        update_attributes(:lawful_presence_update_reason => {:v_type => v_type, :update_reason => update_reason}, :lawful_presence_rejected => true )
    end
    reject!(verification_attr(authority.first))
    "#{v_type} was rejected."
  end

  def update_verification_type(v_type, update_reason, *authority)
    case v_type
      when "DC Residency"
        update_attributes(:is_state_resident => true, :residency_update_reason => update_reason, :residency_determined_at => TimeKeeper.datetime_of_record, :local_residency_validation => "valid")
      when "Social Security Number"
        update_attributes(:ssn_validation => "valid", :ssn_update_reason => update_reason)
      when "American Indian Status"
        update_attributes(:native_validation => "valid", :native_update_reason => update_reason)
      else
        lawful_presence_determination.authorize!(verification_attr(authority.first))
        update_attributes(:lawful_presence_update_reason => {:v_type => v_type, :update_reason => update_reason} )
    end
    (all_types_verified? && !fully_verified?) ? verify_ivl_by_admin(authority.first) : "#{v_type} successfully verified."
  end

  def redetermine_verification!(verification_attr)
    revert!(verification_attr)
    coverage_purchased_no_residency!(verification_attr)
  end

  def is_type_verified?(type)
    case type
      when "DC Residency"
        residency_verified?
      when "Social Security Number"
        ssn_verified?
      when "American Indian Status"
        native_verified?
      else
        lawful_presence_verified?
    end
  end

  def ensure_validation_states
    ensure_ssn_validation_status
    ensure_native_validation
  end

  def ensure_native_validation
    if (tribal_id.nil? || tribal_id.empty?)
      self.native_validation = "na"
    else
      self.native_validation = "outstanding" if native_validation == "na"
    end
  end

  def ensure_ssn_validation_status
    if self.person && self.person.ssn.blank?
      self.ssn_validation = "na"
    end
  end

  def citizenship_immigration_processing?
    dhs_pending? || ssa_pending?
  end

  def processing_residency_24h?
    return false if self.residency_determined_at.nil?
    residency_pending? && ((self.residency_determined_at + 24.hours) > DateTime.now)
  end

  def sensitive_information_changed(field, person_params)
    if field == "dob"
      person.send(field) != Date.strptime(person_params[field], "%Y-%m-%d")
    elsif field == "ssn"
      person.send(field).to_s != person_params[field].tr("-", "")
    else
      person.send(field).to_s != person_params[field]
    end
  end

  def record_transition(*args)
    workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event,
      user_id: SAVEUSER[:current_user_id]
    )
  end

  def verification_attr(*authority)
    authority = authority.first == "curam" ? "curam" : "hbx"
    OpenStruct.new({:determined_at => Time.now,
                    :vlp_authority => authority
                   })
  end
end
