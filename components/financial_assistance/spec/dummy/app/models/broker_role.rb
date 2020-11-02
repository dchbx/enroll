# frozen_string_literal: true

# rubocop:disable all

class BrokerRole
  include Mongoid::Document
  include Mongoid::Timestamps

  PROVIDER_KINDS = %w[broker assister].freeze
  BROKER_UPDATED_EVENT_NAME = "acapi.info.events.broker.updated"

  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }.freeze

  BROKER_CARRIER_APPOINTMENTS = {"Aetna Health Inc" => nil,
                                 "Aetna Life Insurance Company" => nil,
                                 "Carefirst Bluechoice Inc" => nil,
                                 "Group Hospitalization and Medical Services Inc" => nil,
                                 "Kaiser Foundation" => nil,
                                 "Optimum Choice" => nil,
                                 "United Health Care Insurance" => nil,
                                 "United Health Care Mid Atlantic" => nil}.freeze

  embedded_in :person

  field :aasm_state, type: String

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  field :market_kind, type: String
  field :languages_spoken, type: Array, default: ["en"]
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean
  field :license, type: Boolean
  field :training, type: Boolean
  field :carrier_appointments, type: Hash, default: BROKER_CARRIER_APPOINTMENTS

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  def broker_agency_profile=(new_broker_agency)
    if new_broker_agency.is_a? BenefitSponsors::Organizations::BrokerAgencyProfile
      if new_broker_agency.nil?
        self.benefit_sponsors_broker_agency_profile_id = nil
      else
        raise ArgumentError, "expected BenefitSponsors::Organizations::BrokerAgencyProfile class" unless new_broker_agency.is_a? BenefitSponsors::Organizations::BrokerAgencyProfile
        self.benefit_sponsors_broker_agency_profile_id = new_broker_agency._id
        @broker_agency_profile = new_broker_agency
      end
    elsif new_broker_agency.nil?
      self.broker_agency_profile_id = nil
    else
      raise ArgumentError, "expected BrokerAgencyProfile class" unless new_broker_agency.is_a? BrokerAgencyProfile
      self.broker_agency_profile_id = new_broker_agency._id
      @broker_agency_profile = new_broker_agency
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    if self.benefit_sponsors_broker_agency_profile_id.nil?
      @broker_agency_profile = BrokerAgencyProfile.find(broker_agency_profile_id) if has_broker_agency_profile?
    else
      @broker_agency_profile = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => benefit_sponsors_broker_agency_profile_id).first.broker_agency_profile if has_broker_agency_profile?
    end
  end

  def has_broker_agency_profile?
    self.benefit_sponsors_broker_agency_profile_id.present? || self.broker_agency_profile_id.present?
  end

  class << self
    def find(id)
      return nil if id.blank?
      people = Person.where("broker_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_role : nil
    end
  end
end

# rubocop:enable all

