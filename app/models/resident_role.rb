class ResidentRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  include SetCurrentUser
  include Mongoid::Attributes::Dynamic

  RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.residency.verification_request"

  embedded_in :person

  embeds_one :lawful_presence_determination, as: :ivl_role
  embeds_many :paper_applications, as: :documentable

  field :is_applicant, type: Boolean  # Consumer is applying for benefits coverage
  field :is_active, type: Boolean, default: true
  field :bookmark_url, type: String, default: nil
  field :is_state_resident, type: Boolean, default:true
  field :residency_determined_at, type: DateTime

  field :contact_method, type: String, default: "Only Paper communication"
  field :language_preference, type: String, default: "English"

  delegate :hbx_id,           to: :person, allow_nil: true
  delegate :ssn, :ssn=,       to: :person, allow_nil: true
  delegate :dob, :dob=,       to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true
  delegate :tribal_id,          :tribal_id=,         to: :person, allow_nil: true
  delegate :is_incarcerated,    :is_incarcerated=,   to: :person, allow_nil: true

  delegate :citizen_status, :citizenship_result,:vlp_verified_date, :vlp_authority, :vlp_document_id, to: :lawful_presence_determination_instance
  delegate :citizen_status=, :citizenship_result=,:vlp_verified_date=, :vlp_authority=, :vlp_document_id=, to: :lawful_presence_determination_instance

  validates_presence_of :dob, :gender

  accepts_nested_attributes_for :person, :paper_applications

  embeds_many :local_residency_responses, class_name:"EventResponse"

  after_initialize :setup_lawful_determination_instance

  alias_method :is_incarcerated?,   :is_incarcerated

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  def families
    Family.by_residentRole(self)
  end

  def self.find(resident_role_id)
    resident_role_id = BSON::ObjectId.from_string(resident_role_id) if resident_role_id.is_a? String
    @person_find = Person.where("resident_role._id" => resident_role_id).first.resident_role unless resident_role_id.blank?
  end

  def self.all
    Person.all_resident_roles
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

  def is_active?
    self.is_active
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

  def latest_active_tax_household_with_year(year)
    person.primary_family.latest_household.latest_active_tax_household_with_year(year)
  rescue => e
    log("#4287 person_id: #{person.try(:id)}", {:severity => 'error'})
    nil
  end

  def start_residency_verification_process
    notify(RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => self.person})
  end

  def update_by_person(*args)
    person.addresses = []
    person.phones = []
    person.emails = []
    person.update_attributes(*args)
  end


  def find_paper_application_by_key(key)
    candidate_paper_applications = paper_applications
    if person.primary_family.present?
      person.primary_family.family_members.flat_map(&:person).each do |family_person|
        next unless family_person.resident_role.present?
        candidate_paper_applications << family_person.resident_role.paper_applications
      end
      candidate_paper_applications.uniq!
    end

    return nil if candidate_paper_applications.nil?

    candidate_paper_applications.detect do |document|
      next if document.identifier.blank?
      doc_key = document.identifier.split('#').last
      doc_key == key
    end
  end

  private
  def mark_residency_denied(*args)
    self.residency_determined_at = Time.now
    self.is_state_resident = false
  end

  def mark_residency_authorized(*args)
    self.residency_determined_at = Time.now
    self.is_state_resident = true
  end

  def residency_pending?
    is_state_resident.nil?
  end

  def residency_denied?
    (!is_state_resident.nil?) && (!is_state_resident)
  end

  def residency_verified?
    is_state_resident?
  end

end
