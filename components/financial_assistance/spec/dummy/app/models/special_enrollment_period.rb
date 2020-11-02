# frozen_string_literal: true

class SpecialEnrollmentPeriod
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include ScheduledEventService
  include TimeHelper
  include BenefitSponsors::Concerns::Observable
  include BenefitSponsors::ModelEvents::SpecialEnrollmentPeriod

  after_save :notify_on_save

  embedded_in :family
  embeds_many :comments, as: :commentable, cascade_callbacks: true

  # for employee gaining medicare qle
  attr_accessor :selected_effective_on

  field :qualifying_life_event_kind_id, type: BSON::ObjectId

  # Date Qualifying Life Event occurred
  field :qle_on, type: Date
  field :is_valid, type: Boolean

  # Comments made by admin_comment
  # field :admin_comment, type: String  #Removing this, using polymorphic comment association.

  # Date coverage starts
  field :effective_on_kind, type: String

  # Date coverage takes effect
  field :effective_on, type: Date

  # Timestamp when SEP was reported to HBX
  field :submitted_at, type: DateTime

  field :title, type: String

  # Date Enrollment Period starts
  field :start_on, type: Date

  # Date Enrollment Period ends
  field :end_on, type: Date

  # QLE Answer to specific question
  field :qle_answer, type: String

  # Next Possible Event Date
  field :next_poss_effective_date, type: Date

  # Date Option 1
  field :option1_date, type: Date

  # Date Option 2
  field :option2_date, type: Date

  # Date Option 3
  field :option3_date, type: Date

  # Date Options Array
  field :optional_effective_on, type: Array, default: []

  # CSL#
  field :csl_num, type: String

  # MARKET KIND
  field :market_kind, type: String

  # ADMIN FLAG
  field :admin_flag, type: Boolean

  validate :optional_effective_on_dates_within_range, :next_poss_effective_date_within_range

  validates :csl_num,
            length: { minimum: 5, maximum: 10, message: "should be a minimum of 5 digits" },
            allow_blank: true,
            numericality: true

  validates_presence_of :start_on, :end_on, :message => "is invalid"
  validates_presence_of :qualifying_life_event_kind_id, :qle_on, :effective_on_kind, :submitted_at
  validate :end_date_follows_start_date, :is_eligible?

  scope :shop_market,         ->{ where(:qualifying_life_event_kind_id.in => QualifyingLifeEventKind.shop_market_events.map(&:id) + QualifyingLifeEventKind.shop_market_non_self_attested_events.map(&:id)) }
  scope :individual_market,   ->{ where(:qualifying_life_event_kind_id.in => QualifyingLifeEventKind.individual_market_events.map(&:id) + QualifyingLifeEventKind.individual_market_non_self_attested_events.map(&:id)) }

  after_initialize :set_submitted_at

  add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_special_enrollment_events]

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  def contains?(compare_date)
    return false unless start_on.present? && end_on.present?
    (start_on <= compare_date) && (compare_date <= end_on)
  end
end
