# frozen_string_literal: true

class EmployerProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_kind, type: String
  field :sic_code, type: String

  embeds_many :plan_years, cascade_callbacks: true, validate: true
  embedded_in :organization

  field :entity_kind, type: String
  field :sic_code, type: String

  field :no_ssn, type: Boolean, default: false
  field :enable_ssn_date, type: DateTime
  field :disable_ssn_date, type: DateTime

#  field :converted_from_carrier_at, type: DateTime, default: nil
#  field :conversion_carrier_id, type: BSON::ObjectId, default: nil

  # Workflow attributes
  field :aasm_state, type: String, default: "applicant"


  field :profile_source, type: String, default: "self_serve"
  field :contact_method, type: String, default: "Only Electronic communications"
  field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }
  field :xml_transmitted_timestamp, type: DateTime

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  embeds_one  :employer_attestation
  accepts_nested_attributes_for :inbox

  after_initialize :build_nested_models

  def self.find(id)
    organizations = Organization.where("employer_profile._id" => BSON::ObjectId.from_string(id))
    !organizations.empty? ? organizations.first.employer_profile : nil
  end

  def active_plan_year; end

  def is_converting?; end

  def census_employees
    []
  end

  private

  def build_nested_models
    build_inbox if inbox.nil?
  end
end
