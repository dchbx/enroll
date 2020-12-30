# frozen_string_literal: true

# rubocop:disable all

class BrokerAgencyProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization

  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :primary_broker_role_id, type: BSON::ObjectId
  field :default_general_agency_profile_id, type: BSON::ObjectId

  field :languages_spoken, type: Array, default: ["en"] # TODO
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date

  field :ach_routing_number, type: String
  field :ach_account_number, type: String

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :home_page, :home_page=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_fake_fein, :is_fake_fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  embeds_one :inbox, as: :recipient, cascade_callbacks: true
  # embeds_many :documents, as: :documentable
  accepts_nested_attributes_for :inbox

  after_initialize :build_nested_models

  def self.find(id)
    organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
    !organizations.empty? ? organizations.first.broker_agency_profile : nil
  end

  def primary_broker_role=(new_primary_broker_role = nil)
    if new_primary_broker_role.present?
      raise ArgumentError, "expected BrokerRole class" unless new_primary_broker_role.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker_role._id
    else
      unset("primary_broker_role_id")
    end
    @primary_broker_role = new_primary_broker_role
  end

  def primary_broker_role
    return @primary_broker_role if defined? @primary_broker_role
    @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  class << self
    def find(id)
      return nil if id.blank?
      organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      !organizations.empty? ? organizations.first.broker_agency_profile : nil
    end
  end

  private

  def build_nested_models
    build_inbox if inbox.nil?
  end
end

# rubocop:enable all
