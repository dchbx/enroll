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
  delegate :is_physically_disabled, to: :person, allow_nil: true
  delegate :citizen_status, to: :person, allow_nil: true
  delegate :indian_tribe_member, to: :person, allow_nil: true
  delegate :naturalized_citizen, to: :person, allow_nil: true
  delegate :eligible_immigration_status, to: :person, allow_nil: true
  delegate :is_dc_resident?, to: :person, allow_nil: true
  delegate :ivl_coverage_selected, to: :person
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

  def applicant_of_application(application)
    application.active_applicants.where(family_member_id: self.id).first
  end

  def family_mem_attr_changed?(params)
    (personal_details_changed?(params) &&
        params["dob"].to_date == dob.to_date &&
        params["ssn"].tr("-", '') == ssn &&
        params["no_ssn"] == (person.no_ssn.present? ? person.no_ssn : "0") &&
        params["relationship"] == relationship && personal_queries_changed?(params) &&
        params["eligible_immigration_status"] == (eligible_immigration_status.present? ? eligible_immigration_status.to_s : "false") &&
        ethnicity_changed?(params) &&
        no_dc_address?(params) &&
        address_changed?(params["addresses"])).present?
  end

  def primary_mem_attr_changed?(params)
    (personal_details_changed?(params) &&
        personal_queries_changed?(params) &&
        ethnicity_changed?(params) &&
        no_dc_address?(params) &&
        params["no_dc_address_reason"].to_s == person.no_dc_address_reason &&
        (params["name_sfx"].empty? ? nil : params["name_sfx"]) == name_sfx &&
        phone_or_email_changed?(params["phones_attributes"], "full_phone_number", {:type => :phones, :trim => true}) &&
        address_changed?(params["addresses_attributes"]) &&
        phone_or_email_changed?(params["emails_attributes"], "address", {:type => :emails})).present?
  end

  def ethnicity_changed?(params)
    params["ethnicity"] == ethnicity
  end

  def personal_details_changed?(params)
    (params["first_name"] == first_name &&
        (params["middle_name"].empty? ? nil : params["middle_name"]) == middle_name &&
        params["last_name"] == last_name &&
        params["gender"] == gender)
  end

  def no_dc_address?(params)
    params["no_dc_address"] == (person.no_dc_address.present? ? person.no_dc_address.to_s : "false")
  end

  def personal_queries_changed?(params)
    (params["is_applying_coverage"] == is_applying_coverage.to_s &&
        params["us_citizen"] == person.us_citizen.to_s &&
        params["naturalized_citizen"] == naturalized_citizen.to_s &&
        params["indian_tribe_member"] == indian_tribe_member.to_s &&
        params["tribal_id"] == tribal_id &&
        params["is_incarcerated"] == is_incarcerated.to_s &&
        params["is_physically_disabled"] == is_physically_disabled.to_s)
  end

  def phone_or_email_changed?(params, slice, options = {})
    status = []
    params.each do |key, val|
      val.slice(slice.to_sym).each do |attr_idx, attr|
        status << attr.present?
      end
    end
    p_values_exist = status.include?(true)

    if person.send(options[:type]).present? && p_values_exist
      status = []
      params.each do |key, val|
        val.slice(slice.to_sym).each do |attr_idx, attr|
          attr = attr.gsub(/[^\d]/, '') if options[:trim]
          status << (person.send(options[:type])[key.to_i].send(attr_idx.to_sym).to_s == attr) if person.send(options[:type])[key.to_i].present?
        end
      end
      r_value = status.all? {|s| s == true}
    elsif !person.send(options[:type]).present? && p_values_exist
      r_value = false
    elsif person.send(options[:type]).present? && !p_values_exist
      r_value = false
    else
      r_value = true
    end
    return r_value
  end

  def address_changed?(params)
    if person.addresses.present?
      is_same_db = is_same_dependent_as_primary?(params)
      is_same_with_params = is_same_with_params?(params)
      is_params_empty = is_params_empty?(params)
      is_params_same_with_primary = is_params_same_with_primary?(params)

      if is_same_db && is_same_with_params
        true
      elsif !is_same_db  && is_same_with_params
        true
      elsif is_same_db && !is_same_with_params && !is_params_empty
        false
      elsif is_same_db && is_params_empty
        true
      elsif !is_same_db  && !is_same_with_params && is_params_same_with_primary
        true
      end
    else
      true
    end
  end

  def is_same_with_params?(params)
    status = []
    params.each do |key, val|
      val.each do |attr_idx, attr|
        status << (person.addresses[key.to_i].send(attr_idx.to_sym) == attr) if person.addresses[key.to_i].present?
      end
    end
    return status.all? {|s| s == true}
  end

  def is_params_same_with_primary?(params)
    status = []
    params.each do |key, val|
      val.each do |attr_idx, attr|
        status << (family.primary_family_member.person.addresses[key.to_i].send(attr_idx.to_sym) == attr) if person.addresses[key.to_i].present?
      end
    end
    return status.all? {|s| s == true}
  end

  def is_params_empty?(params)
    status = []
    params.each do |key, val|
      val.except("kind").each do |attr_idx, attr|
        status << (attr.empty?)
      end
    end
    return status.all? {|s| s == true}
  end

  def is_same_dependent_as_primary?(params)
    status = []
    params.each do |key, val|
      val.each do |attr_idx, attr|
        status << (family.primary_family_member.person.addresses[key.to_i].send(attr_idx.to_sym) == person.addresses[key.to_i].send(attr_idx.to_sym)) if person.addresses[key.to_i].present?
      end
    end
    return status.all? {|s| s == true}
  end

  private

  def no_duplicate_family_members
    return unless family
    family.family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:family_members, "Duplicate family_members for person: #{k}\n")
    end
  end
end
