# frozen_string_literal: true

# Profile
# Base class with attributes, validations and constraints common to all Profile classes
# embedded in an Organization
class Profile
  include Mongoid::Document
  include Mongoid::Timestamps
  # include BenefitSponsors::ModelEvents::Profile

  embedded_in :organization,  class_name: "BenefitSponsors::Organizations::Organization"

  # Profile subclass may sponsor benefits
  field :is_benefit_sponsorship_eligible, type: Boolean,  default: false
  field :contact_method,                  type: Symbol,   default: :paper_and_electronic

  # TODO: Add logic to manage benefit sponsorships for Gapped coverage, early termination, banned employers

  # Share common attributes across all Profile kinds
  delegate :hbx_id,                   to: :organization, allow_nil: false
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba,        :dba=,        to: :organization, allow_nil: true
  delegate :fein,       :fein=,       to: :organization, allow_nil: true
  delegate :entity_kind,              to: :organization, allow_nil: true

  embeds_many :office_locations,
              class_name: "BenefitSponsors::Locations::OfficeLocation", cascade_callbacks: true

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true,
                      class_name: "BenefitSponsors::Inboxes::Inbox"

  # Use the Document model for managing any/all documents associated with Organization
  has_many :documents, as: :documentable,
                       class_name: "BenefitSponsors::Documents::Document"

  validates_presence_of :office_locations, :contact_method
  accepts_nested_attributes_for :office_locations, allow_destroy: true

  # @abstract profile subclass is expected to implement #initialize_profile
  # @!method initialize_profile
  # Initialize settings for the abstract profile
  after_initialize :initialize_profile, :build_nested_models

  alias is_benefit_sponsorship_eligible? is_benefit_sponsorship_eligible
  # TODO: Maybe add
  # validates :contact_method,
  #  inclusion: { in: ::BenefitMarkets::CONTACT_METHOD_KINDS, message: "%{value} is not a valid contact method" },
  #  allow_blank: false

  after_save :publish_profile_event
end
