class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  INVITE_TYPES = {
    "census_employee" => "employee_role",
    "broker_role" => "broker_role",
    "broker_agency_staff_role" => "broker_agency_staff_role",
    "employer_staff_role" => "employer_staff_role",
    "assister_role" => "assister_role",
    "csr_role" => "csr_role",
    "hbx_staff_role" => "hbx_staff_role",
    "general_agency_staff_role" => "general_agency_staff_role"
  }
  ROLES = INVITE_TYPES.values
  SOURCE_KINDS = INVITE_TYPES.keys

  field :role, type: String
  field :source_id, type: BSON::ObjectId
  field :source_kind, type: String
  field :aasm_state, type: String
  field :invitation_email, type: String
  field :invitation_email_type, type: String
  field :benefit_sponsors_employer_profile_id, type: String

  belongs_to :user, optional: true

  validates_presence_of :invitation_email, :allow_blank => false
  validates_presence_of :source_id, :allow_blank => false
  validates :source_kind, :inclusion => { in: SOURCE_KINDS }, :allow_blank => false
  validates :role, :inclusion => { in: ROLES }, :allow_blank => false

  validate :allowed_invite_types


  aasm do
    state :sent, initial: true
    state :claimed

    event :claim do
      transitions from: :sent, to: :claimed, :after => Proc.new { |*args| process_claim!(*args) }
    end
  end

  def claim_invitation!(user_obj, redirection_obj)
    self.claim!(:claimed, user_obj, redirection_obj)
  end

  def process_claim!(user_obj, redirection_obj)
    self.user = user_obj
    self.save!
    case self.role
    when "employee_role"
      claim_employee_role(user_obj, redirection_obj)
    when "broker_role"
      claim_broker_role(user_obj, redirection_obj)
    when "broker_agency_staff_role"
      claim_broker_agency_staff_role(user_obj, redirection_obj)
    when "employer_staff_role"
      claim_employer_staff_role(user_obj, redirection_obj)
    when "assister_role"
      claim_assister_role(user_obj, redirection_obj)
    when "csr_role"
      claim_csr_role(user_obj, redirection_obj)
    when "hbx_staff_role"
      claim_hbx_staff_role(user_obj, redirection_obj)
    when "general_agency_staff_role"
      claim_general_agency_staff_role(user_obj, redirection_obj)
    else
      raise "Unrecognized role: #{self.role}"
    end
  end

  def claim_employer_staff_role(user_obj, redirection_obj)
    employer_staff_role = EmployerStaffRole.find(source_id)
    person = employer_staff_role.person
    redirection_obj.create_sso_account(user_obj, person, 15, "individual") do
      user_obj.roles << "employer_staff" unless user_obj.roles.include?("employer_staff")
      user_obj.save!
      person.user = current_user
      person.save!
      redirect_to_employer_profile(employer_staff_role.employer_profile)
    end
  end

  def claim_employee_role(user_obj, redirection_obj)
    census_employee = CensusEmployee.find(source_id)
    redirection_obj.redirect_to_employee_match(census_employee)
  end

  def allowed_invite_types
    result_type = INVITE_TYPES[self.source_kind]
    check_role = result_type.blank? ? nil : result_type.downcase
    return if (self.source_kind.blank? || self.role.blank?)
    if result_type != self.role.downcase
      errors.add(:base, "a combination of source #{self.source_kind} and role #{self.role} is invalid")
    end
  end

  def send_invitation!(invitee_name)
    UserMailer.invitation_email(invitation_email, invitee_name, self).deliver_now
  end

  def send_employee_invitation_for_open_enrollment!(census_employee)
    UserMailer.send_employee_open_enrollment_invitation(invitation_email, census_employee, self).deliver_now
  end

  def send_future_employee_invitation_for_open_enrollment!(census_employee)
    UserMailer.send_future_employee_open_enrollment_invitation(invitation_email, census_employee, self).deliver_now
  end

  def send_renewal_invitation!(census_employee)
    UserMailer.renewal_invitation_email(invitation_email, census_employee, self).deliver_now
  end

  def send_initial_employee_invitation!(census_employee)
    UserMailer.initial_employee_invitation_email(invitation_email, census_employee, self).deliver_now
  end

  def self.invite_employee!(census_employee)
    if !census_employee.email_address.blank?
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address
      )
      invitation.send_invitation!(census_employee.full_name)
      invitation
    end
  end

  def self.invite_employee_for_open_enrollment!(census_employee)
    if !census_employee.email_address.blank?
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address
      )
      invitation.send_employee_invitation_for_open_enrollment!(census_employee)
      invitation
    end
  end

  def self.invite_future_employee_for_open_enrollment!(census_employee)
    if !census_employee.email_address.blank?
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address
      )
      invitation.send_future_employee_invitation_for_open_enrollment!(census_employee)
      invitation
    end
  end

  def self.invite_renewal_employee!(census_employee)
    if !census_employee.email_address.blank?
      created_at_range = Date.today.all_day
      return if self.invitation_already_sent?(
        census_employee,
        'employee_role',
        created_at_range,
        "renewal_invitation_email"
      )
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address,
        :invitation_email_type => "renewal_invitation_email",
        :benefit_sponsors_employer_profile_id => census_employee.benefit_sponsors_employer_profile_id.to_s
      )
      invitation.send_renewal_invitation!(census_employee)
      invitation
    end
  end

  def self.invite_initial_employee!(census_employee)
    if !census_employee.email_address.blank?
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address
      )
      invitation.send_initial_employee_invitation!(census_employee)
      invitation
    end
  end

  def self.invitation_already_sent?(source_record, role, created_at_date_or_range, invitation_email_type)
    if source_record.class.name.underscore.to_s == 'census_employee'
      matching_invitation = self.where(
        :role => role, # Pass string such as "employee_role"
        :source_kind => source_record.class.name.underscore.to_s, # Pass string such as "census_employee"
        :invitation_email => source_record.email_address, # String
        :created_at => created_at_date_or_range,
        :benefit_sponsors_employer_profile_id => source_record.benefit_sponsors_employer_profile_id.to_s,
        :invitation_email_type => invitation_email_type
      )
      return true if matching_invitation.present?
    end
  end
end
