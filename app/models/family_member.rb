class FamilyMember
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies

  after_create :create_financial_assistance_applicant

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

  validate :no_duplicate_family_members

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }
  scope :by_primary_member_role, ->{ where(:is_active => true).where(:is_primary_applicant => true) }
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
  delegate :indian_tribe_member, to: :person, allow_nil: true
  delegate :naturalized_citizen, to: :person, allow_nil: true
  delegate :eligible_immigration_status, to: :person, allow_nil: true
  delegate :is_dc_resident?, to: :person, allow_nil: true
  delegate :trigger_hub_call, to: :person
  delegate :is_applying_coverage, to: :person, allow_nil: true

  validates_presence_of :person_id, :is_primary_applicant, :is_coverage_applicant

  associated_with_one :person, :person_id, "Person"

  def former_family=(new_former_family)
    raise ArgumentError.new("expected Family") unless new_former_family.is_a?(Family)
    self.former_family_id = new_former_family._id
    @former_family = new_former_family
  end

  def former_family
    return @former_family if defined? @former_family
    @former_family = Family.find(former_family_id) unless former_family_id.blank?
  end

  def parent
    raise "undefined parent family" unless family
    self.family
  end

  def households
    # TODO parent.households.coverage_households.where()
  end

  def aptc_benchmark_amount
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}
    slcsp = benefit_coverage_period.second_lowest_cost_silver_plan
    ehb = benefit_coverage_period.second_lowest_cost_silver_plan.ehb
    cost = slcsp.premium_for(TimeKeeper.datetime_of_record, person.age_on(TimeKeeper.datetime_of_record))
    cost * ehb
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
      person.find_relationship_with(family.primary_applicant_person, self.family_id) unless family.primary_applicant_person.blank? || person.blank?
    end
  end

  def relationship
    primary_relationship
  end

  def reactivate!(relationship)
    family.primary_applicant_person.ensure_relationship_with(person, relationship, family.id)
    family.add_family_member(person)
  end

  def self.find(family_member_id)
    return [] if family_member_id.nil?
    family = Family.where("family_members._id" => BSON::ObjectId.from_string(family_member_id)).first
    family.family_members.detect { |member| member._id.to_s == family_member_id.to_s } unless family.blank?
  end

  def create_financial_assistance_applicant
    # If there is an application in progress create an applicant for the added family member.
    if family.applications.present?
      if family.application_in_progress.present?
        family.application_in_progress.applicants.create!({family_member_id: self.id}) unless self.is_primary_applicant?
      end
    end
  end

  def application_for_verifications
    return nil unless family.applications.present?
    family.applications.by_year(family.application_applicable_year).for_verifications.where(:"applicants.family_member_id" => id).order_by(:submitted_at => 'desc').first
  end

  def applicant_of_application(application)
    return nil unless application
    application.active_applicants.where(family_member_id: self.id).first
  end

  def applicant_for_verification
    applicant_of_application(family.latest_applicable_submitted_application)
  end

  private

  def no_duplicate_family_members
    return unless family
    family.family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:family_members, "Duplicate family_members for person: #{k}\n")
    end
  end
end
