class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include BelongsToFamilyMember

  embedded_in :hbx_enrollment

  field :applicant_id, type: BSON::ObjectId
  field :carrier_member_id, type: String
  field :is_subscriber, type: Boolean, default: false

  field :premium_amount, type: Money
  field :applied_aptc_amount, type: Money, default: 0.0

  field :eligibility_date, type: Date
  field :coverage_start_on, type: Date
  field :coverage_end_on, type: Date

  validates_presence_of :applicant_id, :is_subscriber, :eligibility_date,# :premium_amount,
    :coverage_start_on

  validate :check_primary_applicant_selected_during_enrollment

  validate :end_date_gt_start_date
  delegate :ivl_coverage_selected, to: :family_member

  def family
    hbx_enrollment.family if hbx_enrollment.present?
  end

  def covered?
    (coverage_end_on.blank? || coverage_end_on >= TimeKeeper.date_of_record) ? true : false
  end

  def family_member
    self.hbx_enrollment.household.family.family_members.detect do |fm|
      fm.id == applicant_id
    end
  end

  def update_current(updates)
    hbx_enrollment.hbx_enrollment_members.where(id: id).update_all(updates)
  end

  def primary_relationship
    return @primary_relationship unless @primary_relationship.blank?
    @primary_relationship = family_member.primary_relationship
  end

  def person
    return @person unless @person.blank?
    @person = family_member.person
  end

  def age_on_effective_date
    return @age_on_effective_date unless @age_on_effective_date.blank?
    dob = person.dob
    return unless coverage_start_on.present?
    age = coverage_start_on.year - dob.year

    # Shave off one year if coverage starts before birthday
    if coverage_start_on.month == dob.month
      age -= 1 if coverage_start_on.day < dob.day
    else
      age -= 1 if coverage_start_on.month < dob.month
    end

    @age_on_effective_date = age
  end

  def is_subscriber?
    self.is_subscriber
  end

  def self.new_from(coverage_household_member:)
    new(
      applicant_id: coverage_household_member.family_member_id,
      is_subscriber: coverage_household_member.is_subscriber
    )
  end

  def is_covered_on?(coverage_date)
    if coverage_end_on.present? && coverage_end_on < coverage_date
      false
    else
      true
    end
  end

  private

  def end_date_gt_start_date
    return unless coverage_end_on.present?
    if coverage_end_on < coverage_start_on
      self.errors.add(:coverage_end_on, "Coverage start date must preceed or equal end date")
    end
  end

  def check_primary_applicant_selected_during_enrollment
    return true #FixMe
    if self.hbx_enrollment.subscriber.nil?
      self.errors.add(:is_subscriber, "You must select the primary applicant to enroll in the healthcare plan.")
    end
  end
end
