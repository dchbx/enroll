class User
  MIN_USERNAME_LENGTH = 8
  MAX_USERNAME_LENGTH = 60
  MAX_SAME_CHAR_LIMIT = 4
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :timeoutable, :authentication_keys => {email: false, login: true}

  validates_presence_of :oim_id
  validates_uniqueness_of :oim_id, :case_sensitive => false
  validate :password_complexity
  validate :oim_id_rules
  validates_uniqueness_of :email,:case_sensitive => false
  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true
  validates_format_of :email, with: Devise::email_regexp , allow_blank: true, :message => "(optional) is invalid"

  def oim_id_rules
    if oim_id.present? && oim_id.match(/[;#%=|+,">< \\\/]/)
      errors.add :oim_id, "cannot contain special charcters ; # % = | + , \" > < \\ \/"
    elsif oim_id.present? && oim_id.length < MIN_USERNAME_LENGTH
      errors.add :oim_id, "must be at least #{MIN_USERNAME_LENGTH} characters"
    elsif oim_id.present? && oim_id.length > MAX_USERNAME_LENGTH
      errors.add :oim_id, "can NOT exceed #{MAX_USERNAME_LENGTH} characters"
    end
  end

  def password_complexity
    if password.present? and not password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d ]).+$/)
      errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit, and one character that is not a digit or letter or space"
    elsif password.present? and password.match(/#{::Regexp.escape(oim_id)}/i)
      errors.add :password, "cannot contain username"
    elsif password.present? and password_repeated_chars_limit(password)
      errors.add :password, "cannot repeat any character more than #{MAX_SAME_CHAR_LIMIT} times"
    elsif password.present? and password.match(/(.)\1\1/)
      errors.add :password, "must not repeat consecutive characters more than once"
    elsif password.present? and !password.match(/(.*?[a-zA-Z]){4,}/)
      errors.add :password, "must have at least 4 alphabetical characters"
    end
  end

  def password_repeated_chars_limit(password)
    return true if password.chars.group_by(&:chr).map{ |k,v| v.size}.max > MAX_SAME_CHAR_LIMIT
    false
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def valid_attribute?(attribute_name)
    self.valid?
    self.errors[attribute_name].blank?
  end

  def self.password_invalid?(password)
    user = User.new(oim_id: 'example1', password: password)
    !user.valid_attribute?('password')
  end

  def self.generate_valid_password
    password = Devise.friendly_token.first(16)
    password = password + "aA1!"
    password = password.squeeze
    if password_invalid?(password)
      password = generate_valid_password
    else
      password
    end
  end

  field :hints, type: Boolean, default: true
  # for i18L
  field :preferred_language, type: String, default: "en"

  ## Enable Admin approval
  ## Seed: https://github.com/plataformatec/devise/wiki/How-To%3a-Require-admin-to-activate-account-before-sign_in
  field :approved, type: Boolean, default: true

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ##RIDP
  field :identity_verified_date, type: Date
  field :identity_final_decision_code, type: String
  field :identity_final_decision_transaction_id, type: String
  field :identity_response_code, type: String
  field :identity_response_description_text, type: String

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String
  field :idp_uuid, type: String

  field :authentication_token
  field :roles, :type => Array, :default => []

  # Oracle Identity Manager ID
  field :oim_id, type: String, default: ""

  field :last_portal_visited, type: String
  field :idp_verified, type: Boolean, default: false

  has_one :person
  accepts_nested_attributes_for :person, :allow_destroy => true

  def has_hbx_staff_role?
    has_role?(:hbx_staff) || self.try(:person).try(:hbx_staff_role)
  end

  def has_csr_role?
    has_role?(:csr)
  end

  def has_broker_agency_staff_role?
    has_role?(:broker_agency_staff)
  end

  def has_broker_role?
    has_role?(:broker)
  end

  def has_role?(role_sym)
    return false if self.person_id.blank?
    roles.any? { |r| r == role_sym.to_s }
  end

  def person_id
    return nil unless person.present?
    person.id
  end

  def switch_to_idp!
    self.idp_verified = true
    begin
      self.save!
    rescue => e
      message = "#{e.message}; "
      message = message + "user: #{self}, "
      message = message + "errors.full_messages: #{self.errors.full_messages}, "
      message = message + "stacktrace: #{e.backtrace}"
      log(message, {:severity => "error"})
      raise e
    end
  end
end
