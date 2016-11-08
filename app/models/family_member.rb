class FamilyMember
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies

  embedded_in :family

  # Person responsible for this family
  field :is_primary_applicant, type: Boolean, default: false

  # Person is applying for coverage
  field :is_coverage_applicant, type: Boolean, default: true

  # Person who authorizes auto-renewal eligibility check
  field :is_consent_applicant, type: Boolean, default: false

  field :is_active, type: Boolean, default: true

  field :person_id, type: BSON::ObjectId
  field :broker_role_id, type: BSON::ObjectId

  # Immediately preceding family where this person was a member
  field :former_family_id, type: BSON::ObjectId

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }

  embeds_many :hbx_enrollment_exemptions
  accepts_nested_attributes_for :hbx_enrollment_exemptions

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  delegate :id, to: :family, prefix: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :first_name, to: :person, allow_nil: true
  delegate :last_name, to: :person, allow_nil: true
  delegate :middle_name, to: :person, allow_nil: true
  delegate :full_name, to: :person, allow_nil: true
  delegate :name_pfx, to: :person, allow_nil: true
  delegate :name_sfx, to: :person, allow_nil: true
  delegate :date_of_birth, to: :person, allow_nil: true
  delegate :dob, to: :person, allow_nil: true
  delegate :ssn, to: :person, allow_nil: true
  delegate :gender, to: :person, allow_nil: true
  # consumer fields
  delegate :race, to: :person, allow_nil: true
  delegate :ethnicity, to: :person, allow_nil: true
  delegate :language_code, to: :person, allow_nil: true
  delegate :is_tobacco_user, to: :person, allow_nil: true
  delegate :is_incarcerated, to: :person, allow_nil: true
  delegate :tribal_id, to: :person, allow_nil: true
  delegate :is_disabled, to: :person, allow_nil: true
  delegate :citizen_status, to: :person, allow_nil: true
  delegate :is_dc_resident?, to: :person, allow_nil: true
  delegate :ivl_coverage_selected, to: :person

  validates_presence_of :person_id, :is_primary_applicant, :is_coverage_applicant

  associated_with_one :person, :person_id, "Person"

  after_create :update_family_status_when_create
  after_update :update_family_status_when_destroy

  def former_family=(new_former_family)
    raise ArgumentError.new("expected Family") unless new_former_family.is_a?(Family)
    self.former_family_id = new_former_family._id
    @former_family = new_former_family
  end

  def former_family
    return @former_family if defined? @former_family
    @former_family = Family.find(former_family_id) unless former_family_id.blank?
  end

  def update_family_status_when_create
    parent.update_aptc_block_status
  end

  def update_family_status_when_destroy
    parent.update_aptc_block_status unless is_active
  end

  def parent
    raise "undefined parent family" unless family
    self.family
  end

  def households
    # TODO parent.households.coverage_households.where()
  end

  def broker=(new_broker)
    return unless new_broker.is_a? BrokerRole
    self.broker_role_id = new_broker._id
  end

  def broker
    BrokerRole.find(self.broker_role_id) unless self.broker_role_id.blank?
  end

  def is_primary_applicant?
    self.is_primary_applicant
  end

  def is_consent_applicant?
    self.is_consent_applicant
  end

  def is_coverage_applicant?
    self.is_coverage_applicant
  end

  def is_active?
    self.is_active
  end

  def primary_relationship
    if is_primary_applicant?
      "self"
    else
      family.primary_applicant_person.find_relationship_with(person) unless family.primary_applicant_person.blank? || person.blank?
    end
  end

  def relationship
    primary_relationship
  end

  def reactivate!(relationship)
    family.primary_applicant_person.ensure_relationship_with(person, relationship)
    family.add_family_member(person)
  end

  def update_relationship(relationship)
    return if (primary_relationship == relationship)
    family.remove_family_member(person)
    self.reactivate!(relationship)
    family.save!
  end

  def self.find(family_member_id)
    Family.find_family_member(family_member_id)
  end
end
