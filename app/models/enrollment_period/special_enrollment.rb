class EnrollmentPeriod::SpecialEnrollment < EnrollmentPeriod::Base

  embedded_in :family

  # for employee gaining medicare qle
  attr_accessor :selected_effective_on

  field :qualifying_life_event_kind_id, type: BSON::ObjectId

  # Date Qualifying Life Event occurred
  field :qle_on, type: Date

  # Date coverage starts
  field :effective_on_kind, type: String

  # Date coverage takes effect
  field :effective_on, type: Date

  # Timestamp when SEP was reported to HBX
  field :submitted_at, type: DateTime

  validates_presence_of :qualifying_life_event_kind_id, :qle_on

  before_create :set_submitted_at

  def qualifying_life_event_kind=(new_qualifying_life_event_kind)
    raise ArgumentError.new("expected QualifyingLifeEventKind") unless new_qualifying_life_event_kind.is_a?(QualifyingLifeEventKind)
    self.qualifying_life_event_kind_id = new_qualifying_life_event_kind._id
    self.title = new_qualifying_life_event_kind.title
    @qualifying_life_event_kind = new_qualifying_life_event_kind
    set_sep_dates
    @qualifying_life_event_kind
  end

  def qualifying_life_event_kind
    return @qualifying_life_event_kind if defined? @qualifying_life_event_kind
    @qualifying_life_event_kind = QualifyingLifeEventKind.find(self.qualifying_life_event_kind_id)
  end

  def qle_on=(new_qle_date)
    write_attribute(:qle_on, new_qle_date)
    set_date_period
    set_sep_dates
    qle_on
  end

  def effective_on_kind=(new_effective_on_kind)
    write_attribute(:effective_on_kind, new_effective_on_kind)
    set_sep_dates
    effective_on_kind
  end

  def is_active?
    return false if start_on.blank? || end_on.blank?
    (start_on..end_on).include?(TimeKeeper.date_of_record)
  end

  def duration_in_days
    return nil if start_on.blank? || end_on.blank?
    end_on - start_on
  end

  def self.find(search_id)
    family = Family.by_special_enrollment_period_id(search_id).first
    family.special_enrollment_periods.detect() { |sep| sep._id == search_id } unless family.blank?
  end

private
  def set_sep_dates
    return unless @qualifying_life_event_kind.present? && qle_on.present? && effective_on_kind.present?
    set_effective_on
    set_submitted_at
  end

  def set_date_period
    return unless @qualifying_life_event_kind.present?
    self.start_on = qle_on - @qualifying_life_event_kind.pre_event_sep_in_days.days
    self.end_on   = qle_on + @qualifying_life_event_kind.post_event_sep_in_days.days

    # Use end_on date as boundary guard for lapsed SEPs
    @reference_date = [TimeKeeper.date_of_record, end_on].min
    @earliest_effective_date = [@reference_date, qle_on].max
    start_on..end_on
  end

  def set_effective_on
    return unless self.start_on.present? && self.qualifying_life_event_kind.present?

    self.effective_on = case effective_on_kind
      when "date_of_event"
        qle_on
      when "exact_date"
        qle_on
      when "first_of_month"
        first_of_month_effective_date
      when "first_of_next_month"
        first_of_next_month_effective_date
      when "fixed_first_of_next_month"
        fixed_first_of_next_month_effective_date
    end
  end

  def set_submitted_at
    self.submitted_at ||= TimeKeeper.datetime_of_record
  end

  def first_of_month_effective_date
    if @reference_date.day <= Setting.individual_market_monthly_enrollment_due_on
      @earliest_effective_date.end_of_month + 1.day
    else
      @earliest_effective_date.next_month.end_of_month + 1.day
    end
  end

  def first_of_next_month_effective_date
    if qualifying_life_event_kind.is_dependent_loss_of_coverage?
      qualifying_life_event_kind.employee_gaining_medicare(qle_on, selected_effective_on)
    elsif qualifying_life_event_kind.is_moved_to_dc?
      calculate_effective_on_for_moved_qle
    else
      @earliest_effective_date.end_of_month + 1.day
    end
  end

  def fixed_first_of_next_month_effective_date
    qle_on.end_of_month + 1.day
  end

  def calculate_effective_on_for_moved_qle
    if qle_on <= TimeKeeper.date_of_record
      TimeKeeper.date_of_record.end_of_month + 1.day
    else
      if qle_on == qle_on.beginning_of_month
        qle_on.beginning_of_month
      else
        qle_on.end_of_month + 1.day
      end
    end
  end

end
