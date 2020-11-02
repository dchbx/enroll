module AuthorizationConcern
  extend ActiveSupport::Concern

  included do
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable, :lockable,
           :recoverable, :jwt_authenticatable, :rememberable, :trackable, :timeoutable, :authentication_keys => {email: false, login: true},
           jwt_revocation_strategy: self

    ## Database authenticatable
    field :email,              type: String, default: ""
    field :encrypted_password, type: String, default: ""
    field :authentication_token

    ## Recoverable
    embeds_many :security_question_responses
    field :reset_password_token,   type: String
    field :reset_password_sent_at, type: Time
    field :identity_confirmed_token, type: String

    ## Rememberable
    field :remember_created_at, type: Time

    ## Trackable
    field :sign_in_count,      type: Integer, default: 0
    field :current_sign_in_at, type: Time
    field :last_sign_in_at,    type: Time
    field :current_sign_in_ip, type: String
    field :last_sign_in_ip,    type: String

    ## Lockable
    field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
    field :unlock_token,    type: String # Only if unlock strategy is :email or :both
    field :locked_at,       type: Time

    ## Confirmable
    # field :confirmation_token,   type: String
    # field :confirmed_at,         type: Time
    # field :confirmation_sent_at, type: Time
    # field :unconfirmed_email,    type: String # Only if using reconfirmable

    validate :password_complexity
    validates_presence_of     :password, if: :password_required?
    validates_confirmation_of :password, if: :password_required?
    validates_length_of       :password, within: Devise.password_length, allow_blank: true
    validates_format_of :email, with: Devise::email_regexp , allow_blank: true, :message => "is invalid"

    scope :locked, ->{ where(:locked_at.ne => nil) }
    scope :unlocked, ->{ where(locked_at: nil) }

    before_save :ensure_authentication_token

    has_many :whitelisted_jwts

    def generate_jwt(scope, audience)
      token, payload = Warden::JWTAuth::UserEncoder.new.call(
        self,
        scope,
        audience
      )
      on_jwt_dispatch(token, payload)
      token
    end

    def on_jwt_dispatch(token, payload)
      whitelisted_jwts.create!(
        token: token,
        jti: payload['jti'],
        aud: payload['aud'],
        exp: Time.at(payload['exp'].to_i)
      )
    end

    def self.jwt_revoked?(payload, user)
      !user.whitelisted_jwts.where(payload.slice('jti', 'aud')).any? do |jwt|
        Time.now > Time.at(jwt.exp.to_i)
      end
    end

    def revoke_all_jwts!
      WhitelistedJwt.where({:user_id => self.id}).delete_all
    end

    def self.revoke_jwt(payload, user)
      WhitelistedJwt.where({:user_id => user.id}).delete_all
    end

    def ensure_authentication_token
      if authentication_token.blank?
        self.authentication_token = generate_authentication_token
      end
      true
    end

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end

    def lockable_notice
      self.locked_at.nil? ? 'unlocked' : 'locked'
    end

    def locked?
      self.locked_at.present?
    end

    def password_required?
      !persisted? || !password.nil? || !password_confirmation.nil?
    end

    def needs_to_provide_security_questions?
      security_question_responses.length < 3
    end

    def password_complexity
      if password.present? and not password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d ]).+$/)
        errors.add :password, "Your password must include at least 1 lowercase letter, 1 uppercase letter, 1 number, and 1 character that’s not a number, letter, or space."
      elsif password.present? and password.match(/#{::Regexp.escape(oim_id)}/i)
        errors.add :password, "Password cannot contain username"
      elsif password.present? and password_repeated_chars_limit(password)
        errors.add :password, "Password cannot repeat any character more than #{MAX_SAME_CHAR_LIMIT} times"
      elsif password.present? and password.match(/(.)\1\1/)
        errors.add :password, "Password must not repeat consecutive characters more than once"
      elsif password.present? and !password.match(/(.*?[a-zA-Z]){4,}/)
        errors.add :password, "Password must have at least 4 alphabetical characters"
      end
    end

    def password_repeated_chars_limit(password)
      return true if password.chars.group_by(&:chr).map{ |k,v| v.size}.max > MAX_SAME_CHAR_LIMIT
      false
    end

    def lock!
      if locked_at.nil?
        self.lock_access!
      else
        self.unlock_access!
      end
    end
  end

  class_methods do
    MAX_SAME_CHAR_LIMIT = 4

    def password_invalid?(password)
      ## TODO: oim_id is an explicit dependency to the User class
      resource = self.new(oim_id: 'example1', password: password)
      !resource.valid_attribute?('password')
    end

    def generate_valid_password
      password = Devise.friendly_token.first(16)
      password = password + "aA1!"
      password = password.squeeze
      if password_invalid?(password)
        password = generate_valid_password
      else
        password
      end
    end

    def find_by_authentication_token(token)
      where(authentication_token: token).first
    end

    def send_reset_password_instructions(attributes={})
      recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
      if !recoverable.approved?
        recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
      elsif recoverable.persisted?
        recoverable.send_reset_password_instructions
      end
      recoverable
    end

    def login_captcha_required?(login)
      begin
        logins_before_captcha <= self.or({oim_id: login}, {email: login}).first.failed_attempts
      rescue => e
        true
      end
    end

    def logins_before_captcha
      4
    end

    def has_answered_question? security_question_id
       where(:'security_question_responses.security_question_id' => security_question_id).any?
    end
  end
end
