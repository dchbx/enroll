# frozen_string_literal: true

module EnrollmentPeriod
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String

  # Date Enrollment Period starts
    field :start_on, type: Date

  # Date Enrollment Period ends
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

    def contains?(compare_date)
      return false unless start_on.present? && end_on.present?
      (start_on <= compare_date) && (compare_date <= end_on)
    end


    private

    def end_date_follows_start_date
      return false unless start_on.present? && end_on.present?
      # Passes validation if end_on == start_date
      errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
    end

  end
end
