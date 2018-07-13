require 'active_support/concern'

module SponsoredBenefits
  module Concerns::Dob
    extend ActiveSupport::Concern

    included do
      validate :date_of_birth_is_past
    end

    def dob_to_string
      self.dob.blank? ? "" : self.dob.strftime("%Y%m%d")
    end

    def date_of_birth
      self.dob.blank? ? nil : self.dob.strftime("%m/%d/%Y")
    end

    def date_of_birth_is_past
      return unless self.dob.present?
      errors.add(:dob, "future date: #{self.dob} is invalid date of birth") if TimeKeeper.date_of_record < self.dob
    end

    def age_on(date)
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end
  end
end