# frozen_string_literal: true

class EnrollmentPeriod
  include Mongoid::Document

  embedded_in :benefit_sponsor

  field :title, type: String
  field :start_on, type: Date
  field :end_on, type: Date

  validates_presence_of :start_on, :end_on, :message => "is invalid"
  validate :end_date_follows_start_date

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  alias effective_date= start_on=
  alias effective_date start_on

  private

  def end_date_follows_start_date
    return unless self.end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end


end
