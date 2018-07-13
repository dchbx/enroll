require 'securerandom'

class HbxIdGenerator
  include Singleton

  def self.generate_policy_id
    random_uuid
  end

  def self.generate_member_id
    random_uuid
  end

  def self.generate_organization_id
    random_uuid
  end

  def self.random_uuid
    SecureRandom.uuid.gsub("-","")
  end
end
