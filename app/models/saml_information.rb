class SamlInformation

  class MissingKeyError < StandardError
    def initialize(key)
      super("Missing required key: #{key}")
    end
  end

  include Singleton

  REQUIRED_KEYS = [
    'assertion_consumer_service_url',
    'assertion_consumer_logout_service_url',
    'issuer',
    'idp_entity_id',
    'idp_sso_target_url',
    'idp_slo_target_url',
    'idp_cert',
    'name_identifier_format',
    'idp_cert_fingerprint',
    'idp_cert_fingerprint_algorithm',
    'curam_landing_page_url',
    'saml_logout_url',
    'account_conflict_url',
    'account_recovery_url',
    'iam_login_url',
    'curam_broker_dashboard',
    'kp_pay_now_issuer',
    'kp_pay_now_url',
    'kp_pay_now_relay_state',
    'kp_pay_now_private_key_location',
    'kp_pay_now_x509_cert_location',
    'kp_pay_now_audience'
  ]

  attr_reader :config

  # TODO: I have a feeling we may be using this pattern
  #       A LOT.  Look into extracting it if we repeat.
  def initialize
    @config = YAML.load_file(File.join(Rails.root,'config', 'saml.yml'))
    ensure_configuration_values(@config)
  end

  def ensure_configuration_values(conf)
    REQUIRED_KEYS.each do |k|
      if @config[k].blank?
        raise MissingKeyError.new(k)
      end
    end
  end

  def self.define_key(key)
    define_method(key.to_sym) do
      config[key.to_s]
    end
    self.instance_eval(<<-RUBYCODE)
      def self.#{key.to_s}
        self.instance.#{key.to_s}
      end
    RUBYCODE
  end

  REQUIRED_KEYS.each do |k|
    define_key k
  end

end
